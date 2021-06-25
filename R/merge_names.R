#' Surname probability merging function.
#'
#' \code{merge_names} merges surnames in user-input dataset with corresponding 
#'  race/ethnicity probabilities from U.S. Census Surname List and Spanish Surname List.
#'
#' This function allows users to match names in their dataset with the U.S. 
#'  Census Surname List (from 2000 or 2010) and Spanish Surname List to obtain 
#'  Pr(Race | Surname) for each of the five major racial groups.
#'  
#'  By default, the function matches surnames to the Census list as follows: 
#'  1) Search raw surnames in Census surname list; 
#'  2) Remove any punctuation and search again; 
#'  3) Remove any spaces and search again; 
#'  4) Remove suffixes (e.g., Jr) and search again; 
#'  5) Split double-barreled surnames into two parts and search first part of name; 
#'  6) Split double-barreled surnames into two parts and search second part of name; 
#'  7) For any remaining names, impute probabilities using distribution 
#'  for all names not appearing on Census list.
#'  
#'  Each step only applies to surnames not matched in a previous ste. 
#'  Steps 2 through 7 are not applied if \code{clean.surname} is FALSE.
#'  
#'  Note: Any name appearing only on the Spanish Surname List is assigned a 
#'  probability of 1 for Hispanics/Latinos and 0 for all other racial groups.
#'
#' @param voter.file An object of class \code{data.frame}. Must contain a field 
#'  named 'surname' containing list of surnames to be merged with Census lists.
#' @param surname.year An object of class \code{numeric} indicating which year 
#'  Census Surname List is from. Accepted values are \code{2010} and \code{2000}. 
#'  Default is \code{2010}.
#' @param clean.surname A \code{TRUE}/\code{FALSE} object. If \code{TRUE}, 
#' any surnames in \code{\var{voter.file}} that cannot initially be matched 
#' to surname lists will be cleaned, according to U.S. Census specifications, 
#' in order to increase the chance of finding a match. Default is \code{TRUE}.
#' @param impute.missing A \code{TRUE}/\code{FALSE} object. If \code{TRUE}, 
#' race/ethnicity probabilities will be imputed for unmatched names using  
#' race/ethnicity distribution for all other names (i.e., not on Census List).
#' Default is \code{TRUE}.
#' @return Output will be an object of class \code{data.frame}. It will 
#'  consist of the original user-input data with additional columns that 
#'  specify the part of the name matched with Census data (\code{\var{surname.match}}), 
#'  and the probabilities Pr(Race | Surname) for each racial group 
#'  (\code{\var{p_whi}} for White, \code{\var{p_bla}} for Black, 
#'  \code{\var{p_his}} for Hispanic/Latino, 
#'  \code{\var{p_asi}} for Asian and Pacific Islander, and 
#'  \code{\var{p_oth}} for Other/Mixed).
#'
#' @import devtools
#'
#' @examples
#' data(voters)
#' merge_surnames(voters)
#'
#' @export
merge_names <- function(voter.file, namesToUse, clean.names = F, impute.missing = T) {
  
  # check the names 
  if(namesToUse == 'last') {
    if(!("last" %in% names(voter.file))) 
      stop("Voter data frame needs to have a column named 'last'.")
    
  } else if(namesToUse == 'last, first') {
    if(!("last" %in% names(voter.file)) || !("first" %in% names(voter.file))) 
      stop("Voter data frame needs to have a column named 'last' and a column called 'first'.")
    
  } else if(namesToUse == 'last, first, middle') {
    if(!("last" %in% names(voter.file)) || !("first" %in% names(voter.file)) 
       || !("middle" %in% names(voter.file))) 
      stop("Voter data frame needs to have a column named 'last', a column called 'first', and a column called 'middle'.")
  }
  
  # read in the name files
  library(stringr)
  #last <- read_csv('~/Documents/GitHub/wru-data/dict_last_merged.csv', na = "")
  #first <- read_csv('~/Documents/GitHub/wru-data/dict_first.csv', na = "")
  #mid <- read_csv('~/Documents/GitHub/wru-data/dict_middle.csv', na = "")
  mid[is.na(mid$middle_name),]$middle_name = ''
  
  ## Convert names in voter file to upper case
  p_eth <- c("p_whi", "p_bla", "p_his", "p_asi", "p_oth")
  df <- voter.file
  df$caseid <- 1:nrow(df)
  
  df$lastname.match <- df$lastname.upper <- toupper(as.character(df$last))
  if(grepl('first', namesToUse))
    df$firstname.match <- df$firstname.upper <- toupper(as.character(df$first))
  if(grepl('middle', namesToUse)) {
    df$middlename.match <- df$middlename.upper <- toupper(as.character(df$middle))
    df$middlename.match[is.na(df$middlename.match)] <- ''
  }
    
  ## Merge Surnames with Census List (No Cleaning Yet)
  df <- merge(df, last, by.x = "lastname.match", by.y = "last_name", all.x = TRUE)
  if(grepl('first', namesToUse))
    df <- merge(df, first, by.x = "firstname.match", by.y = "first_name", all.x = TRUE)
  if(grepl('middle', namesToUse)) {
    df <- merge(df, mid, by.x = "middlename.match", by.y = "middle_name", all.x = TRUE)
  }

  if(namesToUse == 'last' && sum(!(df$lastname.upper %in% last$last_name)) == 0)
     return(df[order(df$caseid), c(names(voter.file), "lastname.match", p_eth)])
  if(namesToUse == 'last, first' && sum(!(df$lastname.match %in% last$last_name)) == 0 &&
      sum(!(df$firstname.upper %in% first$first_name)) == 0)
    return(df[order(df$caseid), c(names(voter.file), "lastname.match", "firstname.match", p_eth)])
  if(namesToUse == 'last, first, middle' && sum(!(df$lastname.match %in% last$last_name)) == 0 &&
      sum(!(df$firstname.upper %in% first$first_name)) == 0 && sum(!(df$middlename.upper %in% middle$middle_name)) == 0)
    return(df[order(df$caseid), c(names(voter.file), "lastname.match", "firstname.match", "middlename.match", p_eth)])


#  df1 <- df[df$surname.upper %in% surnames$surname, ] #Matched surnames
#  df2 <- df[df$surname.upper %in% surnames$surname == F, ] #Unmatched surnames
  
  ## Clean Surnames (if Specified by User)
  if (clean.names) {
    
    ## Remove All Punctuation and Try Merge Again
    df2$surname.match <- gsub("[^[:alnum:] ]", "", df2$surname.upper)
    df2 <- merge(df2[names(df2) %in% p_eth == F], surnames[c("surname", p_eth)], by.x = "surname.match", by.y = "surname", all.x = TRUE)
    if (nrow(df2[df2$surname.match %in% surnames$surname, ]) > 0) {
      df1 <- rbind(df1, df2[df2$surname.match %in% surnames$surname, ])
      df2 <- df2[df2$surname.match %in% surnames$surname == F, ]
      if (nrow(df2[df2$surname.match %in% surnames$surname, ]) > 0) {df2$surname.match <- ""}
    }

    ## Remove All Spaces and Try Merge Again
    df2$surname.match <- gsub(" ", "", df2$surname.match)
    df2 <- merge(df2[names(df2) %in% p_eth == F], surnames[c("surname", p_eth)], by.x = "surname.match", by.y = "surname", all.x = TRUE)
    if (nrow(df2[df2$surname.match %in% surnames$surname, ]) > 0) {
      df1 <- rbind(df1, df2[df2$surname.match %in% surnames$surname, ])
      df2 <- df2[df2$surname.match %in% surnames$surname == F, ]
      if (nrow(df2[df2$surname.match %in% surnames$surname, ]) > 0) {df2$surname.match <- ""}
    }

    ## Remove Jr/Sr/III Suffixes
    suffix <- c("JUNIOR", "SENIOR", "THIRD", "III", "JR", " II", " J R", " S R", " IV")
    for (i in 1:length(suffix)) {
      df2$surname.match <- ifelse(substr(df2$surname.match, nchar(df2$surname.match) - (nchar(suffix)[i] - 1), nchar(df2$surname.match)) == suffix[i], 
                                  substr(df2$surname.match, 1, nchar(df2$surname.match) - nchar(suffix)[i]), 
                                  df2$surname.match)
    }
    df2$surname.match <- ifelse(nchar(df2$surname.match) >= 7, 
                                ifelse(substr(df2$surname.match, nchar(df2$surname.match) - 1, nchar(df2$surname.match)) == "SR", 
                                       substr(df2$surname.match, 1, nchar(df2$surname.match) - 2), 
                                       df2$surname.match), 
                                df2$surname.match) #Remove "SR" only if name has at least 7 characters
    df2 <- merge(df2[names(df2) %in% p_eth == F], surnames[c("surname", p_eth)], by.x = "surname.match", by.y = "surname", all.x = TRUE)
    if (nrow(df2[df2$surname.match %in% surnames$surname, ]) > 0) {
      df1 <- rbind(df1, df2[df2$surname.match %in% surnames$surname, ])
      df2 <- df2[df2$surname.match %in% surnames$surname == F, ]
      if (nrow(df2[df2$surname.match %in% surnames$surname, ]) > 0) {df2$surname.match <- ""}
    }

    ## Names with Hyphens or Spaces, e.g. Double-Barreled Names
    df2$surname2 <- df2$surname1 <- NA
    df2$surname1[grep("-", df2$surname.upper)] <- sapply(strsplit(grep("-", df2$surname.upper, value = T), "-"), "[", 1)
    df2$surname2[grep("-", df2$surname.upper)] <- sapply(strsplit(grep("-", df2$surname.upper, value = T), "-"), "[", 2)  
    df2$surname1[grep(" ", df2$surname.upper)] <- sapply(strsplit(grep(" ", df2$surname.upper, value = T), " "), "[", 1)
    df2$surname2[grep(" ", df2$surname.upper)] <- sapply(strsplit(grep(" ", df2$surname.upper, value = T), " "), "[", 2)
    
    ## Use first half of name to merge in priors
    df2$surname.match <- as.character(df2$surname1)
    df2 <- merge(df2[names(df2) %in% c(p_eth) == F], surnames[c("surname", p_eth)], by.x = "surname.match", by.y = "surname", all.x = TRUE)[names(df2)]
    if (nrow(df2[df2$surname.match %in% surnames$surname, ]) > 0) {
      df1 <- rbind(df1, df2[df2$surname.match %in% surnames$surname, names(df2) %in% names(df1)])
      df2 <- df2[df2$surname.match %in% surnames$surname == F, ]
      if (nrow(df2[df2$surname.match %in% surnames$surname, ]) > 0) {df2$surname.match <- ""}
    }
    
    ## Use second half of name to merge in priors for rest
    df2$surname.match <- as.character(df2$surname2)
    df2 <- merge(df2[names(df2) %in% c(p_eth, "surname1", "surname2") == F], surnames[c("surname", p_eth)], by.x = "surname.match", by.y = "surname", all.x = TRUE)[names(df2) %in% c("surname1", "surname2") == F]
    if (nrow(df2[df2$surname.match %in% surnames$surname, ]) > 0) {
      df1 <- rbind(df1, df2[df2$surname.match %in% surnames$surname, names(df2) %in% names(df1)])
      df2 <- df2[df2$surname.match %in% surnames$surname == F, ]
      if (nrow(df2[df2$surname.match %in% surnames$surname, ]) > 0) {df2$surname.match <- ""}
    }
  }

  ## For unmatched names, just fill with a 1 
  library(dplyr)
  warning(paste(paste(sum(is.na(df$p_whi_last)), " (", round(100*mean(is.na(df$p_whi_last)), 1), "%) indivduals' last names were not matched.", sep = "")))
  if(grepl('first', namesToUse)) {
    warning(paste(paste(sum(is.na(df$p_whi_first)), " (", round(100*mean(is.na(df$p_whi_first)), 1), "%) indivduals' first names were not matched.", sep = "")))
  }
  if(grepl('middle', namesToUse)) {
    warning(paste(paste(sum(is.na(df$p_whi_middle)), " (", round(100*mean(is.na(df$p_whi_middle)), 1), "%) indivduals' middle names were not matched.", sep = "")))
  }
  
  for(i in grep("p_", names(df))) {
    df[,i] <- coalesce(df[,i], 1)
  }

  # return the data
  if(namesToUse == 'last')
    return(df[order(df$caseid), c(names(voter.file), "lastname.match", paste(p_eth, "last", sep = "_"))])
  else if(namesToUse == 'last, first')
    return(df[order(df$caseid), c(names(voter.file), "lastname.match", "firstname.match", 
                                  paste(p_eth, "last", sep = "_"), paste(p_eth, "first", sep = "_"))])
  else if(namesToUse == 'last, first, middle')
    return(df[order(df$caseid), c(names(voter.file), "lastname.match", "firstname.match", "middlename.match", 
                                  paste(p_eth, "last", sep = "_"), paste(p_eth, "first", sep = "_"), paste(p_eth, "middle", sep = "_"))])
  
}