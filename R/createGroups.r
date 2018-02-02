#' Function that assigns elements to N sets and minimizes differences in
#' sets.
#'
#' This function can be used to assign a set of items to N
#' groups. Differences between groups are minimized in regard to
#' specified criteria (E.g.: minimize differences in mean test scores
#' between school classes).
#'
#' @param data A data.frame containing the set that is to be
#'     regrouped. All assignment criteria must be columns of this
#'     data.frame.
#' @param criteria_scale A string vector naming all continuous,
#'     numerical columns in `data` that are to be considered as criteria
#'     in set assignment. Can be left out if only nominal variables are
#'     to be equalized between groups.
#' @param criteria_nominal A string vector naming all nominal column
#'     variables in `data`, that are to be considered as criteria in set
#'     assignment. Can be left out, if only continuous variables are to
#'     be equalized between groups.  A maximum of two nominal criteria
#'     can be realized.
#' @param sets_n How many equal groups are to be created.
#' @param repetitions How many reassignment trials are to be made.
#' @param tolerance_nominal Use only if argument `criteria_nominal` is
#'     also passed. This argument indicates the tolerated frequency
#'     deviations for nominal variables (and their combinations) between
#'     newly created sets. Must be a one-value vector if one nominal
#'     variable is passed; must be a three-value vector if two nominal
#'     variables are passed (the second value is the tolerance value for
#'     the second variable and the third value is the tolerance value
#'     for the combinations of both variables). If unsure how to use
#'     this parameter, start using large tolerance values and observe
#'     the group assigments.
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
#'
#' @return A \code{data.frame}. Contains all columns from argument
#'     `data` and additionally a column variable `$newSet`. This columns
#'     contains the set assigment that produced the best fit in the
#'     previous iterations.
#' 
#' @export
#' 
#' @author Martin Papenberg \email{martin.papenberg@@hhu.de}
#'

create_groups <- function(data, criteria_scale=NULL, criteria_nominal=NULL,
                         sets_n, repetitions=1, tolerance_nominal=rep(Inf, 3),
                         equalize=list(mean), write_file = FALSE) {

   # how many items are to be reassigned
   cases <- nrow(data)
    
   # CHECK FOR ERRORS IN USER INPUT
   errMsg <- "error in function reassign.set:"
   
   if (class(data) != "data.frame") {
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
      if( is.na( match(i, names(data)) ))  {
         stop(paste(errMsg, "`", i, "` is not a column in the passed data.frame", sep=""))
      }
   }   

   # Warnings
   # no criterion was passed - just shuffle the data.frame
   if (is.null(criteria_scale) && is.null(criteria_nominal)) {
      warning("warning: no assignment criterion was passed.
              Given data.frame is returned in random order.")
      return(data[with(data, order(sample(cases))), ])
   }
   # set number does not divide total number of cases, proceed but let user know
   if (cases %% sets_n != 0) {
       warning(paste(" set number (", sets_n, ") does not divide length of data (",
                  cases, "). New sets will have unequal sizes.", sep=""))
   }
   # check for NA values in criterion columns
   test.frame <- data.frame(data[criteria_scale], data[criteria_nominal])
   no.na      <- sum(apply(test.frame, 2, function(x) any(is.na(x)))) == 0
   if (!no.na) {
      warning("Warning: NA values were found in assigment criteria")
   }
   
   # START RANDOMLY ASSIGNING CASES TO SETS
   cat("Start simulation ","-", format(Sys.time(), "%a %b %d %X %Y"), "\n")
   setAssign <- rep_len(1:sets_n, nrow(data))

   # Generate new item sets randomly, select those sets for which differences in
   # regards to the specified criteria are minimized

   # case: a set was passed that allready was optizmized in a recent run
   if (!is.null(data$newSet)) {
      if (length(unique(data$newSet)) != sets_n) {
          stop(paste(errMsg, "Variable newSet was found in data.frame
               that was passed. Number of different groups in variable
               newSet is not equal to the value that was passed via
               argument `sets_n`"))
          }
      cat("Variable newSet was found - trying to improve previous optimization \n")
      best_var <- checkVar(data, criteria_scale, equalize)
      newSet  <- data
   }
   else {
      best_var <- Inf # start value of variance between new sets
   }
   
   # no newSet was passed, start anew completely
   for (i in 1:repetitions) {
      partials <- ceiling(repetitions / 10)
      if (i %% partials == 0) { cat("working on iteration", i, "\n") }
      # here a random set is generated
      itemDataRnd <- data[with(data, order(sample(cases))), ]
      itemDataRnd$newSet <- setAssign

      ### consider making nominal variable checking an external method!!
      # Check if nominal variables are OK
      # Nominal variable checking is done in the following WHILE loop
      if (!is.null(criteria_nominal)) {
         number_criteria_nominal <- length(criteria_nominal) 
         nominal_satisfied <- FALSE
         while (nominal_satisfied == FALSE) {
            # how is first nominal variable in the new sets distributed
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
            
            # check if assignment of nominal variables to new sets is as required
            if (assignFailed) {
               # data does not meet the required distribution of nominal variables
               # make new!
               itemDataRnd <- data[with(data, order(sample(cases))), ]
               itemDataRnd$newSet <- setAssign
            } else if (!assignFailed) {
               # If we get here, distribution for all nominal variables is OK
               # only such sets are considered further
               nominal_satisfied <- TRUE
            }
         }
      }
      
      # NOMINAL CRITERIA ARE FINISHED

      if (!is.null(criteria_scale)) {

#          # NOW CONTINUOUS VARIABLES ARE CHECKED! What is done: Minimize variance between
         # item sets in regard to the functions specified in argument `equalize`; `mean`
         # is the default function for which differences between sets are minimized
         sumVar <- checkVar(itemDataRnd, criteria_scale, equalize)
         # Case: better fit was found, save the set
         if (sumVar < best_var) {
            cat("Success! Improved set similarity on iteration", i, "\n")
            newSet  <- itemDataRnd
            if (writeFile) { # write new best set to file
               write.table(file="newSet.csv", newSet, dec=",", sep=";", row.names=FALSE)
            }
            best_var <- sumVar
         }
      # if no continuous criteria were specified
      } else if (is.null(criteria_scale)) {
         newSet <- itemDataRnd
         break  # first hit is OK
      }
   }
    
   ## END of all iterations
   cat("End simulation ","-", format(Sys.time(), "%a %b %d %X %Y"), "\n")
   if (writeFile) {
      write.table(file="newSet.csv", newSet, dec=",", sep=";", row.names=FALSE)
   }
   return(newSet)
}


# method that returns the  total variance between groups in all scale criteria
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
