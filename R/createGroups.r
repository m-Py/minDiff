#' Function that assigns elements to N sets and minimizes differences in
#' sets.
#'
#' This function can be used to assign a set of items to N
#' groups. Differences between groups are minimized in regard to
#' specified criteria (E.g.: minimize differences in mean test scores
#' between school classes).
#'
#' @param dat A data.frame containing the set that is to be
#'     regrouped. All assignment criteria must be columns of this
#'     data.frame.
#' @param criteria_scale A string vector naming all continuous,
#'     numerical columns in `dat` that are to be considered as criteria
#'     in set assignment. Can be left out if only nominal variables are
#'     to be equalized between groups.
#' @param criteria_nominal A string vector naming all nominal column
#'     variables in `dat`, that are to be considered as criteria in set
#'     assignment. Can be left out, if only continuous variables are to
#'     be equalized between groups.  A maximum of two nominal criteria
#'     can be realized.
#' @param sets_n How many equal groups are to be created.
#' @param repetitions How many random assignments are to be tested. Only
#'     use if `exact` == FALSE.
#' @param exact Should _all_ possible assignments be tested? This yields
#'     the optimal solution. Defaults to `FALSE`, in which case a random
#'     subset of all possible assignments will be tested.
#' @param tolerance_nominal Use only if argument `criteria_nominal` is
#'     also passed. This argument indicates the tolerated frequency
#'     deviations for nominal variables (and their combinations) between
#'     newly created sets. Must be a one-value vector if one nominal
#'     variable is passed; must be a three-value vector if two nominal
#'     variables are passed (the second value is the tolerance value for
#'     the second variable and the third value is the tolerance value
#'     for the combinations of both variables). It is possible that no
#'     assignment will be found that fits the tolerance requirements; if
#'     unsure how to use this parameter, start using large tolerance
#'     values and observe the group assigments.
#' @param equalize A list of functions. These functions determine which
#'     criterion is minimized between sets: differences in function
#'     return values are minimized. The default function that is
#'     operated on is `mean`; in this case, the mean values of the
#'     specified criteria (via argument `criteria_scale`) are matched
#'     between sets. Can be any function that returns a single value
#'     vector.
#' @param write_file Boolean. Will newly found better fitting sets be
#'     written to a file automatically? (This is helpful if your
#'     simulation runs unexpectedly long and you need to kill it; in
#'     this case the best match is not lost). Defaults to `FALSE`.
#' @param talk Boolean. If `TRUE`, the function will print its progress.
#'
#' @return A \code{data.frame}. Contains all columns from argument `dat`
#'     and additionally a column variable `$newSet`. This columns
#'     contains the set assigment that produced the best fit to the
#'     specified criteria.
#' 
#' @export
#' 
#' @author Martin Papenberg \email{martin.papenberg@@hhu.de}
#'

create_groups <- function(dat, criteria_scale=NULL, criteria_nominal=NULL,
                          sets_n, repetitions=1, exact = FALSE,
                          tolerance_nominal=rep(Inf, 3),
                          equalize=list(mean), write_file = FALSE,
                          talk = TRUE) {

    ## How many items are to be reassigned:
    cases <- nrow(dat)
    ## Check for errors and warnings
    checkInput(dat, sets_n, criteria_scale, criteria_nominal, cases)

    ## Initialize a variable that encodes the assignment to groups
    setAssign  <- sort(rep_len(1:sets_n, cases))
    
    ## Check if a set was passed that was optizmized in a recent run
    if (!is.null(dat$newSet)) {
        if (length(unique(dat$newSet)) != sets_n) {
            stop(paste("Variable newSet was found in data.frame
               that was passed. Number of different groups in variable
               newSet is not equal to the value that was passed via
               argument `sets_n`"))
        }
        if (talk)
            cat("Variable newSet was found - trying to improve previous optimization \n")
        best_var    <- checkVar(dat, criteria_scale, equalize)
        best_assign <- dat$newSet
    } else { ## -> start from scratch
        best_var <- Inf # start value of variance between new sets
        best_assign <- NULL
    }

    if (exact == TRUE) {
        repetitions <- all_combinations(table(setAssign))
    }
    ## for user output
    partials   <- ceiling(repetitions / 10)
    
    ## START iterating
    if (talk)
        cat("Start iteration 1 of", repetitions, "-", format(Sys.time(), "%a %b %d %X %Y"), "\n")

    i <- 1
    while (i <= repetitions) {

        ## generate set assignment:
        if (exact == FALSE) {
            setAssign  <- sample(setAssign)
        } else {
            setAssign  <- next_permutation(setAssign)
        }
        dat$newSet <- setAssign
        
        ## Some output for user:
        if (i %% partials == 0 & talk) {
            cat("working on iteration", i, "\n")
        }
        
        ## Check nominal criteria - only use this assignment if the
        ## nominal criteria are satisfied
        if (!is.null(criteria_nominal)) {
            nominal_okay <- check_nominal(dat, criteria_nominal, tolerance_nominal, cases)
            if (!nominal_okay) next
        }
        
        ## NOW CONTINUOUS VARIABLES ARE CHECKED: What is done: Minimize
        ## variance between item sets in regard to the functions
        ## specified in argument `equalize`; `mean` is the default
        ## function for which differences between sets are minimized.
        if (!is.null(criteria_scale)) {
            ## check the sum of the deviation variance in all criteria
            ## for this assignment:
            sumVar <- checkVar(dat, criteria_scale, equalize)
            ## Better fit was found, save the assignment
            if (sumVar < best_var) {
                if (talk)
                    cat("Success! Improved set similarity on iteration", i, "\n")
                best_assign <- setAssign
                best_var <- sumVar
                write_file(write_file, dat)
            }
        }
        i <- i + 1
    }
    ## END of all iterations

    if (is.null(best_assign)) {
        warning("No assignment was found satisfying the restrictions in your nominal criteria. Try to increase the `tolerance_nominal` parameter or increase `repetitions`.")
    }

    ## return best assignment:
    dat$newSet <- best_assign
    write_file(write_file, dat)
    
    if (talk)
        cat("End of iteration", repetitions, "-", format(Sys.time(), "%a %b %d %X %Y"), "\n")

    return(dat)
}

write_file <- function(write, dat) {
    if (write) {
        write.table(file="newSet.csv", dat, dec=",", sep=";",
                    row.names=FALSE)
    }
}

## Method that checks the user input and generates error or warning messsages
checkInput <- function(dat, sets_n, criteria_scale, criteria_nominal, cases) {
    
    ## CHECK FOR ERRORS IN USER INPUT
    errMsg <- "error in function reassign.set:"
   
    if (class(dat) != "data.frame") {
        stop(paste(errMsg, "first argument must be a data.frame"))
    }
    
    if (length(criteria_nominal) > 2) {
        stop(paste(errMsg, "only two nominal variables can be considered in set creation."))
    }
    
    if (length(criteria_nominal) == 2 && length(tolerance_nominal) < 3) {
        stop(paste(errMsg, "Three tolerance_nominal values must be passed if
                          two nominal criteria are given."))
    }
    
    for (i in c(criteria_scale, criteria_nominal)) {
        if( is.na( match(i, names(dat)) ))  {
            stop(paste(errMsg, "`", i, "` is not a column in the passed data.frame", sep=""))
        }
    }
    ## no criterion was passed: Abort
    if (is.null(criteria_scale) && is.null(criteria_nominal)) {
        stop(paste(errMsg, "no assignment criterion was passed."))
    }
    
    ## Warnings
    ## set number does not divide total number of cases, proceed but let user know
    if (cases %% sets_n != 0) {
        warning(paste("Set number (", sets_n, ") does not divide length of data (",
                      cases, "). Sets have unequal sizes.", sep=""))
    }
    ## check for NA values in criterion columns
    test.frame <- data.frame(dat[criteria_scale], dat[criteria_nominal])
    no.na      <- sum(apply(test.frame, 2, function(x) any(is.na(x)))) == 0
    if (!no.na) {
        warning("Warning: criteria contained NA values.")
    }
}

## method that checks if the group assigment is consistent with the
## specified tolerance level for deviation in categorical variables:
check_nominal <- function(itemDataRnd, criteria_nominal,
                          tolerance_nominal, cases) {
    ## Check if nominal variables are OK
    ## Nominal variable checking is done in the following WHILE loop
    number_criteria_nominal <- length(criteria_nominal)
    nominal_satisfied <- FALSE
    
    ## how is first nominal variable in the new sets distributed
    tmpNomData_1   <- unlist(itemDataRnd[criteria_nominal[1]])
    tmpNomDistr_1  <- table(itemDataRnd$newSet, tmpNomData_1)
    if (length(criteria_nominal) == 1) { # only one nominal variable was passed
        devFromPerfect_1 <- max(check2d_table(tmpNomDistr_1))
        assignFailed     <- devFromPerfect_1 > tolerance_nominal[1]
    } else if (length(criteria_nominal) == 2) { # two nominal criteria
        tmpNomData_2   <- unlist(itemDataRnd[criteria_nominal[2]])
        tmpNomDistr_2  <- table(itemDataRnd$newSet, tmpNomData_2)
        tmpNomDistr_intAct  <- table(itemDataRnd$newSet, tmpNomData_1, tmpNomData_2)
        
        devFromPerfect_1   <- max(check2d_table(tmpNomDistr_1))
        devFromPerfect_2   <- max(check2d_table(tmpNomDistr_2))
        devFromPerfect_int <- max(check3d_table(tmpNomDistr_intAct))
        assignFailed       <- (devFromPerfect_1 > tolerance_nominal[1]) |
            (devFromPerfect_2 > tolerance_nominal[2]) |
            (devFromPerfect_int > tolerance_nominal[3])
    }
    
    ## check if assignment of nominal variables to new sets is as required
    if (!assignFailed) {
        nominal_satisfied <- TRUE
    }
    return(nominal_satisfied)
}

# method that returns the total variance between groups in all scale
# criteria
checkVar <- function(data, criteria_scale, equalize) {
   # varAllCrits: total variance between sets for all criteria in all `equalize`
   # functions
   varAllCrits  <- NULL
   for (t in 1:length(criteria_scale)) {
      # tmpVar_1Crit: variance between sets in the t'th criterion
      # in all `equalize` functions
      tmpVar_1Crit  <- NULL
      for (j in 1:length(equalize)) {
          tmpMeans    <- tapply(scale(data[criteria_scale[t]]),
                                data$newSet, FUN=equalize[[j]], na.rm =TRUE)
          tmpVar_1Crit <- c(tmpVar_1Crit, var(tmpMeans, na.rm =TRUE))
      }
      varAllCrits     <- c(varAllCrits, tmpVar_1Crit)
   }
   sumVar <- sum(varAllCrits)
   return(sumVar)
}

# function that checks if frequency differences of nominal variables are between
# sets; check for one criterion (~ 2D table)
check2d_table <- function(d2_table) {
   # check dimension of table
   if ( length(dim(d2_table)) != 2 ) { stop("error: table dimension must be 2") }
   numberCols  <- dim(d2_table)[2]
   differences <- vector(length=numberCols)
   for (i in 1:numberCols) {
      differences[i] <- max(d2_table[,i]) - min(d2_table[,i])
   }
   return(differences)
} 

# function that checks if frequencies between nominal sets are okay
# in a 3D table
check3d_table <- function(d3_table) {
   if ( length(dim(d3_table)) != 3 ) { stop("error: table dimension must be 3") }
   number3dim  <- dim(d3_table)[3]   
   differences <- NULL
   for (i in 1:number3dim) {
      differences <- c(differences, check2d_table(d3_table[,,i]))
   }
   return(differences)
}

#' Get the next permutation 
#'
#' Each permutation is computed on basis of a passed permutation where
#' lexicographic ordering of the permutations is used to determine the
#' next "higher" permutation. This is an adaption of the
#' `next_permutation` function in C++.
#'
#' @param permutation A vector of elements.
#'
#' @return The next higher permutation of the elements in vector
#'     `permutation` with regard to its lexicographic ordering.
#'
#' @export
#' 
#' @author Martin Papenberg \email{martin.papenberg@@hhu.de}
#' 
next_permutation <- function(permutation) {
    n    <- length(permutation)
    last <- permutation[n]
    i    <- n
    while(last <= permutation[i-1]) {
        last <- permutation[i-1]
        i    <- i - 1
        ## if lexicographic order is already at the maximum:
        if (i-1 == 0) return(sort(permutation))
    }
    ## this algorithm divides the input in a head and a tail; the tail
    ## is monotonically decreasing
    head <- permutation[1:(i-1)]
    tail <- permutation[i:length(permutation)]
    ## which element in the tail is the smallest element that is larger
    ## than the last element in the head?
    larger_values  <- tail[tail > head[length(head)]]
    ## last element of the head:
    final_head <- head[length(head)]
    ## replace last element of head by smallest larger value in tail
    head[length(head)] <- min(larger_values)  
    ## replace smallest larger value in tail by final head element
    tail[max(which(tail == min(larger_values)))] <- final_head
    ## reverse tail before returning
    return(c(head, rev(tail)))
}

#' Compute the number of all possible set assignments
#' 
#' @param x A vector of N set sizes
#' 
#' @return The number of all possible assignments to N sets
#'
all_combinations <- function(x) {
    set_size <- c(sum(x), sum(x) - cumsum(x))
    result   <- 1
    for (i in 1:(length(x)-1)) {
        result <- result * choose(set_size[i], x[i])
    }
    return(result)
}
