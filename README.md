# minDiff

minDiff is an R-package that can be used to assign elements to groups and minimize differences between the created groups, i.e. make elements in all groups as equal as possible. This functionlity is implemented in the method `createGroups()`.

## Installation

Install the `devtools` package first via `install.packages("devtools")`.

Then, to install the minDiff package, type in your R console

`devtools::install_github("m-Py/minDiff")`

## Usage

Load the package via

```S
library("minDiff")
```

To reproduce the following example, install the "MASS" package that contains the data set that is used.

```S
library("MASS")
data(survey)
``` 

The `survey` data set contains some demographic information on a student sample. Imagine you wish to assign students to three different dormitories and want to create a similar groups of students in each house. As a first step, we might want to match average student age. 

To do so, we pass our data set to the function `createGroups()`. We also specify that we want to create three groups whose ages should be equal on average (specified by passing the function `mean` to the argument `equalize`).

```S

equal <- createGroups(survey, criteria_scale=c("Age"), 
                      sets_n = 3, repetitions=10, equalize=list(mean))

````

When the function is executed, we receive a warning: missing values were found in the column "Age" of the survey data set. The function still tries to equalize the age of students between groups.

The returned data.frame `equal` is be a shuffled version of the data.frame `survey`, which has one additional column: newSet -- this is the group assignment variable that we were looking for.

Let's have a look at this:

```S
> table(equal$newSet)
 1  2  3 
79 79 79 
```

The `survey` data set has 237 entries, which can be fit equally into three group. In this case, we are lucky that all groups are of the same size. If the data set had not been a multiplier of the group number, `createGroups()` would have created groups that are of similar size.

 Let's see how successful our attempt was to create equal groups:

```S
> tapply(equal$Age, equal$newSet, mean)
       1        2        3 
20.35449 20.57806 20.19099 
```

Not so bad! But how did it work? In the function call above, we specified another parameter, `repetitions=10`. This means that the function randomly assigned all cases (i.e. students) to three groups ten times, and in the end the most equal group assignment was returned. What is considered most equal has been determined by the parameters `criteria_scale` -- that told the function that student age is to be considered -- and `equalize` that told the function that mean age is to be equalized.

We can do even more assignments to create groups that are even more equal. Note that I simply pass the the `equal` data.frame that was already optimized in the previous run -- this way I do not start completely random all over:


```S

equal <- createGroups(equal, criteria_scale=c("Age"), 
                      sets_n = 3, repetitions=100, equalize=list(mean))

````

```S
> tapply(equal$Age, equal$newSet, mean)
       1        2        3 
20.35976 20.38613 20.37766 
```

Nice!

We may not only wish to minimize differences with regards to age, though. We may for example wish to create equal gender ratios in all dormitories. Let's check how well the assignment that only considered age did in that regard:

```S
> table(equal$newSet, equal$Sex)

    Female Male
  1     36   43
  2     38   41
  3     44   34

```

We can see that gender ratios are very different between dormitories. `createGroups()` offers the possibility to consider categorical variables in its assigment, they are passed via the `criteria_nominal` parameter. Let's try this out:

```S

equal <- createGroups(survey, criteria_scale=c("Age"), 
                      criteria_nominal=c("Sex"), tolerance_nominal=c(1),
                      sets_n = 3, repetitions=100, equalize=list(mean))

````

By specifying the parameter `tolerance_nominal` = 2, we tell the function that we tolerate deviations in the frequency between new sets of no more than 2. Did that work?

```S
> table(equal$newSet, equal$Sex)

    Female Male
  1     40   39
  2     38   40
  3     40   39

```

Note that in this case, we could decrease our tolerance for deviations to 1, but it is impossible to assign the same number of female and male students to all dormitories in this case. If a tolerance of 0 is passed, the function will never stop executing, so be careful with low tolerance values if you are not sure how categories can be assigned to groups.

### Further possibilities

Use more than one categorical and / or scale variables:

```S

equal <- createGroups(survey, criteria_scale=c("Age", "Height"), 
                      criteria_nominal=c("Sex", "Smoke"), 
                      tolerance_nominal=c(1, 4, Inf),
                      sets_n = 3, repetitions=100, equalize=list(mean))

````

Consider more than only the mean in each group: 

```S

equal <- createGroups(survey, criteria_scale=c("Age", "Height"), 
                      criteria_nominal=c("Smoke"), 
                      tolerance_nominal=c(2),
                      sets_n = 3, repetitions=100, equalize=list(mean, sd))

````

## Feedback / Bug reports

Any feedback or reports on bugs is **greatly** appreciated; just open an issue on Github!
