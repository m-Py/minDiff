# minDiff

minDiff is an R-package that can be used to assign elements to a
specified number of groups and minimize differences between created
groups. This functionality is implemented in the method
`create_groups()`.

**Note that this package is no longer maintained, but there is a 
successor package that is under active developement: 
[`anticlust`](https://github.com/m-Py/anticlust).** The
`anticlust` package builds on the theory of cluster analysis to 
create sets of elements that are as similar as possible. 

I created this package to assign stimuli in psychological experiments to
different conditions so that conditions are as equal as possible, a
priori. But I am sure that a wide range of applications is possible (for
an example, see section 'Usage').

## Installation

Install the `devtools` package first via `install.packages("devtools")`.

To install the minDiff package, type in your R console

`devtools::install_github("m-Py/minDiff")`

## Usage

Load the package via

```
library("minDiff")
```

To reproduce the following example, install the "MASS" package that
contains the data set that is used.

```
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

```

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

```
> table(equal$newSet)
 1  2  3 
79 79 79 
```

The `survey` data set has 237 entries, which can be assigned to three
groups of equal size. If the data set had not been a multiplier of the
group number, `create_groups` would have created groups that are of
similar size.

Let's see how successful we were in creating groups of age:

```
> tapply(equal$Age, equal$newSet, mean)
       1        2        3 
20.35449 20.57806 20.19099 
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
age. Note that it is possible to pass a data set that has been optimized
previously; in this case, the program does not start all over, but only
tries find more similar groups than the previous best assignment:

```
equal <- create_groups(equal, criteria_scale = "Age", 
                       sets_n = 3, repetitions = 10000)
                     
> tapply(equal$Age, equal$newSet, mean)
       1        2        3 
20.37028 20.38194 20.37133
```

Nice! How well your groups can match of course depends on the input data.

### Considering more than one criterion

We can pass more than one criterion to `create_groups`. Let's imagine we
also want students to be of equal heights in all dormitories:

```
equal <- create_groups(survey, criteria_scale = c("Age", "Height"), 
                       sets_n = 3, repetitions = 10000)
                      
> tapply(equal$Age, equal$newSet, mean)
       1        2        3 
20.37877 20.35233 20.39244

> tapply(equal$Height, equal$newSet, mean, na.rm=TRUE)
       1        2        3 
172.5658 172.3694 172.2292
```

Note that there were missing values in the variable
`survey$Height`. This is given out as a warning by `create_groups`, but
it will still return a result (and simply disregards the missing value
in the variable height).

### Considering categorical criteria

We may not only wish to minimize differences with regards to age or
height, but we might want to create equal gender ratios in all
dormitories. Let's check in what ratios our previous group assignment
resulted:

```
> table(equal$newSet, equal$Sex)

    Female Male
  1     36   43
  2     38   41
  3     44   34

```

We can see that gender ratios are very different between
dormitories. `create_groups` offers the possibility to consider
categorical variables when creating groups. These are passed via the
`criteria_nominal` parameter. Let's try this out:

```

equal <- create_groups(survey, criteria_scale = "Age", 
                       criteria_nominal = "Sex", tolerance_nominal = 2,
                       sets_n = 3, repetitions = 100)

```

By specifying the parameter `tolerance_nominal = 2`, we tell
`create_groups` that we tolerate deviations between dormitories in the
frequency of female and male students of no more than 2. Did that work?

```
> table(equal$newSet, equal$Sex)

    Female Male
  1     40   39
  2     38   40
  3     40   39
```

Note that in this case, we could decrease our tolerance for deviations
to 1, but it is impossible to assign the same number of female and male
students to all dormitories in this case. If a tolerance value is passed
that cannot be met using the present data and the number of repetitions
that were conducted, `create_groups` will not return an assignment.

### Use more than one categorical variable

It is possible to pass two categorical criteria `create_groups()`. There
is no limit for scale criteria, but only two categorical variables can
be passed.

Here is an example where we want to create dormitories that are similar
with regard to smoker status and gender ratio:

```
equal <- create_groups(survey, criteria_scale = c("Age", "Height"),
                       criteria_nominal = c("Sex", "Smoke"),
                       tolerance_nominal = c(2, 3, Inf), sets_n = 3,
                       repetitions=100)

> table(equal$newSet, equal$Sex)

    Female Male
  1     39   40
  2     40   38
  3     39   40

> table(equal$newSet, equal$Smoke)

    Heavy Never Occas Regul
  1     4    63     6     6
  2     4    62     6     6
  3     3    64     7     5
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

### Use other equalizing functions

I could be interested not only in equalizing mean age between groups,
but also the standard deviation of ages to achieve similar distributions
of age between dormitories. This is possible by passing another function
to the `equalize` parameter.

```
equal <- create_groups(survey, criteria_scale = "Age", 
                      criteria_nominal = "Smoke", 
                      tolerance_nominal = 2,
                      sets_n = 3, repetitions = 500, 
                      equalize = list(mean, sd))

> tapply(equal$Age, equal$newSet, mean)
       1        2        3 
20.21943 20.41986 20.48425 

> tapply(equal$Age, equal$newSet, sd)
       1        2        3 
6.599697 6.995727 5.855852 
```

## "Exact" solution

So far, we tried to minimize differences between groups using repeated
random assignments of students to groups. `create_groups` also offers
the possibility to compute the exact best assignment (with regard to the
specified criteria). You can compute the best assignment by setting the
parameter `exact` to `TRUE` (it defaults to `FALSE`). In this case, all
possible assignments will be tested sequentially. As the number of
assignments growths exponentially with the number of items to be
assigned, this option is not feasible for large data sets. 

This code produces the best assignment of the first 20 students to two
groups. A total of 184,756 assignments is conducted (fun fact: the
number of all possible assignments of students to three groups is 4.16 *
10^110).

```

surv <- head(survey, n = 20)

equal <- create_groups(surv, criteria_scale = "Age", exact = TRUE,
                       sets_n = 2)

> tapply(equal$Age, equal$newSet, mean)
      1       2 
20.3248 20.3168 

```

This ran 48 in seconds on my computer.

## How is the similarity between groups measured

To be written.

## Feedback / Bug reports

Any feedback or reports on bugs is greatly appreciated; just open an
issue or write an email to martin.papenberg at uni-duesseldorf.de.
