# minDiff

minDiff is an R-package that can be used to assign elements to a
specified number of groups and minimize differences between created
groups. 

**Note that this package is no longer maintained, but there is a 
successor package that is under active developement: 
[`anticlust`](https://github.com/m-Py/anticlust).** The
`anticlust` package builds on the theory of cluster analysis to 
create sets of elements that are as similar as possible. Because 
the `minDiff` package still seems to attract some users, I inserted 
`R` code below to reproduce the README examples using the `anticlust` package;
the `anticlust` code runs faster and the results are superior.

## Installation

Install the `devtools` package first via `install.packages("devtools")`.

To install the minDiff package, type in your R console

`devtools::install_github("m-Py/minDiff")`

## Usage

Load the packages `minDiff` and `anticlust` via

```R
library(anticlust) # this is better and you should use it, see below
library(minDiff)
```

To reproduce the following example, install the "MASS" package that
contains the data set that is used.

```R
library("MASS")
data(survey)       # load data set
head(survey, n=10) # look at the data
``` 

The `survey` data set contains some demographic information on a student
sample. Imagine you wish to assign students to three different
dormitories and want to create a similar groups of students in each
house. As a first step, we might want to match average student age.

To do so, we pass our data set to the function `create_groups` and
specify which variable should be made equal in how many sets. 

```R
equal <- create_groups(survey, criteria_scale = "Age", 
                       sets_n = 3, repetitions = 100)
```

By passing the column `Age` to the argument `criteria_scale` we inform
`create_groups` that age is a continuous variable, for which we want to
minimize the differences between groups. `create_groups` returns a
`data.frame` that is saved into the object `equal`. `equal` is actually
the same as the input data `survey`, but it has one additional column:
`newSet` - this is the group assignment variable that was created.

Let's have a look at this:

```R
table(equal$newSet)
#  1  2  3 
# 79 79 79 
```

The `survey` data set has 237 entries, which can be assigned to three
groups of equal size. If the data set had not been a multiplier of the
group number, `create_groups` would have created groups that are of
similar size.

Let's see how successful we were in creating groups of age:

```R
tapply(equal$Age, equal$newSet, mean)
#        1        2        3 
# 20.35449 20.57806 20.19099 
```

Not so bad! But how did it work? In the function call above, we
specified another parameter, `repetitions=100` (which is also the
default value if we do not specify a value for repetition). This means
that the function randomly assigned all cases (i.e. students) to three
groups 100 times, and returned the most equal group assignment. In the
default case, what is considered most equal is the assignment that has
the minimum difference in group means; but we can specify different
criteria if we want to (see below). By varying the parameter
`repetitions` we can increase our chances of creating equal groups. If
we conduct 10,000 repetitions (which is still very fast if we only
consider one variable), the groups will be very similar with regards to
age. Note that random repetitions performs quite okay, but more sophisticated
such as used in `anticlust` improve the results (see below).

Note that it is possible to pass a data set that has been optimized
previously; in this case, the program does not start all over, but only
tries find more similar groups than the previous best assignment:

```R
equal <- create_groups(equal, criteria_scale = "Age", 
                       sets_n = 3, repetitions = 10000)
                     
> tapply(equal$Age, equal$newSet, mean)
       1        2        3 
20.37028 20.38194 20.37133
```

Using the `anticlust` package, we can obtain a better partitioning using the `anticlustering()` function, and the code runs much faster:

```R
library(anticlust)
survey$anticlustering_groups <- anticlustering(
  survey$Age, 
  K = 3, # 3 groups as above
  objective = "variance" # equalizes mean values
)
# The output is a grouping vector, not data frame

tapply(survey$Age, survey$anticlustering_groups, mean)
#        1        2        3 
# 20.37453 20.37446 20.37456 
```

### Considering more than one criterion

We can pass more than one criterion to `create_groups`. Let's imagine we
also want students to be of equal heights in all dormitories:

```R
equal <- create_groups(survey, criteria_scale = c("Age", "Height"), 
                       sets_n = 3, repetitions = 10000)
                      
tapply(equal$Age, equal$newSet, mean)
#        1        2        3 
# 20.37877 20.35233 20.39244

tapply(equal$Height, equal$newSet, mean, na.rm=TRUE)
#        1        2        3 
# 172.5658 172.3694 172.2292
```

Note that there were missing values in the variable
`survey$Height`. This is given out as a warning by `create_groups`, but
it will still return a result (and simply disregards the missing value
in the variable height).

Using the `anticlust` package, we can do better, as follows:

```R

# anticlust needs some prior NA handling, simply impute mean for age
survey$imputed_height <- survey$Height
survey$imputed_height[is.na(survey$imputed_height)] <- mean(survey$Height, na.rm = TRUE)

survey$anticlustering_groups <- anticlustering(
  survey[, c("Age", "imputed_height")], 
  K = 3, # 3 groups as above
  objective = "variance", # equalizes mean values
  standardize = TRUE # because age and height are different in their value range
)

tapply(survey$Age, survey$anticlustering_groups, mean)
#      1        2        3 
# 20.37449 20.37451 20.37454 

tapply(survey$Height, survey$anticlustering_groups, mean, na.rm=TRUE)
#       1        2        3 
# 172.3782 172.3824 172.3818

```

Generally, I would not recommend only equalizing the means between groups,
but also the spread (i.e., the standard deviations), an example of how to do
this in `minDiff` and `anticlust` is given below.

### Considering categorical criteria

We may not only wish to minimize differences with regards to age or
height, but we might want to create equal gender ratios in all
dormitories. Let's check in what ratios our previous group assignment
resulted:

```R
table(equal$newSet, equal$Sex)

  #   Female Male
  # 1     36   43
  # 2     38   41
  # 3     44   34

```

We can see that gender ratios are very different between
dormitories. `create_groups` offers the possibility to consider
categorical variables when creating groups. These are passed via the
`criteria_nominal` parameter. Let's try this out:

```R

equal <- create_groups(survey, criteria_scale = "Age", 
                       criteria_nominal = "Sex", tolerance_nominal = 2,
                       sets_n = 3, repetitions = 100)

```

By specifying the parameter `tolerance_nominal = 2`, we tell
`create_groups` that we tolerate deviations between dormitories in the
frequency of female and male students of no more than 2. Did that work?

```R
table(equal$newSet, equal$Sex)

  #   Female Male
  # 1     40   39
  # 2     38   40
  # 3     40   39
```

Using the `anticlust` package, we can use the `categories` argument to 
consider nominal variables:

```R
survey$anticlustering_groups <- anticlustering(
  survey$Age,
  K = 3,
  objective = "variance",
  categories = survey$Sex
)

table(survey$anticlustering_groups, survey$Sex)

  #   Female Male
  # 1     40   39
  # 2     39   40
  # 3     39   39

```

Note that using `minDiff` a `tolerance_nominal` of 1 will most likely not return
a feasible solution; `anticlust` by default finds the best possible balance
(so there is no need to specify a tolerance level).

### Use more than one categorical variable

It is possible to pass two categorical criteria `create_groups()`. There
is no limit for scale criteria, but only two categorical variables can
be passed. Note that `anticlust` can incoorporate an arbitrary number of
categorical variables.

Here is an example where we want to create dormitories that are similar
with regard to smoker status and gender ratio:

```
equal <- create_groups(survey, criteria_scale = c("Age", "Height"),
                       criteria_nominal = c("Sex", "Smoke"),
                       tolerance_nominal = c(2, 3, Inf), sets_n = 3,
                       repetitions=100)

table(equal$newSet, equal$Sex)

  #   Female Male
  # 1     39   40
  # 2     40   38
  # 3     39   40

table(equal$newSet, equal$Smoke)

  #   Heavy Never Occas Regul
  # 1     4    63     6     6
  # 2     4    62     6     6
  # 3     3    64     7     5
```

Note that the parameter `tolerance_nominal` expects a vector of length 3
if two categorical variables are passed to `criteria_nominal`. These
values indicate tolerances for deviations in the first, the second and
the combined categorical levels. In doubt, use large tolerance values
when starting to optimize your groups and see how well the function is
running. In the upper case I was not interested to assign an equal
number of smoking females and males to each dormitories and considered
both categorical variables independently from each other. So, I set the
tolerance for deviations in the combined groups to infinity.

Using the `anticlust` package, I do not need to worry about tolerance levels
when using more than one categorical criterion (and the results, again, are better 
and the code runs much faster):

```R

survey$anticlustering_groups <- anticlustering(
  survey$Age,
  K = 3,
  objective = "variance",
  categories = survey[, c("Sex", "Smoke")]
)
table(survey$anticlustering_groups, survey$Sex)

  #   Female Male
  # 1     39   39
  # 2     40   39
  # 3     39   40

table(survey$anticlustering_groups, survey$Smoke)
    
  #   Heavy Never Occas Regul
  # 1     4    63     7     5
  # 2     4    63     6     6
  # 3     3    63     6     6

```

### Use other equalizing functions

I could be interested not only in equalizing mean age between groups,
but also the standard deviation of ages to achieve similar distributions
of age between dormitories. This is possible by passing another function
to the `equalize` parameter.

```R
equal <- create_groups(survey, criteria_scale = "Age", 
                      criteria_nominal = "Smoke", 
                      tolerance_nominal = 2,
                      sets_n = 3, repetitions = 500, 
                      equalize = list(mean, sd))

tapply(equal$Age, equal$newSet, mean)
#        1        2        3 
# 20.21943 20.41986 20.48425 

tapply(equal$Age, equal$newSet, sd)
#        1        2        3 
# 6.599697 6.995727 5.855852 
```

In `anticlust`, the "k-plus" objective can be used to equalize means as well
as standard deviations between groups. Again, the results are strongly improved
as compared to `minDiff`.

```R
survey$anticlustering_groups <- anticlustering(
  survey$Age,
  K = 3,
  objective = "kplus",
  categories = survey$Smoke,
  method = "local-maximum" # better algorithm to get similar groups
)

tapply(survey$Age, survey$anticlustering_groups, mean)
#        1        2        3 
# 20.42829 20.34710 20.34815 

tapply(survey$Age, survey$anticlustering_groups, sd)
#        1        2        3 
# 6.502561 6.501436 6.501497 
```

