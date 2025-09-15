##Written by Meghan Byrne - ABMT data sharing####
install.packages("effectsize")
library(effectsize)
library(nlme)
library(plyr)
library(dplyr)
library(lme4)
library(readxl)
library(tidyverse)
library(car)
library(reshape2)
##clear environment##
rm(list=ls())
setwd("/path/to/data")

####PARS####

require(phia)
require(afex)
require(mvinfluence)
require(doBy)
#setup afex
afex_options(factorize=F)
afex_options(es_aov='pes')
afex_options()

#Read in Updated PARS dataset with correct data
Upd_PARS_select <- read.csv(file = "PARS_.csv", sep = ",", header=T, fill = T) %>% mutate_all(as.character)

Upd_PARS_select$Condition <- as.factor(Upd_PARS_select$Condition)
Upd_PARS_select$PARS_RATER_SCORE <- as.numeric(Upd_PARS_select$PARS_RATER_SCORE)
Upd_PARS_select$Visit.Age <- as.numeric(Upd_PARS_select$Visit.Age)
Upd_PARS_select$Sex <- as.factor(Upd_PARS_select$Sex)
Upd_PARS_select$Interval <- as.factor(Upd_PARS_select$Interval)

##REMOVE ANYONE WITH INCOMPLETE PARS##
Upd_PARS_select <- subset(Upd_PARS_select, Upd_PARS_select$PARS_FORM_COMPLETE=="1")

#Run model
fm <- lme(PARS_RATER_SCORE~Condition*Interval + Sex + Visit.Age, random = ~1|SDAN, data = Upd_PARS_select)
anova(fm)
summary(fm)
eta_squared(fm, partial = TRUE)


####CGI####
Raw_CGI_select <- read.csv(file = "CGI.csv", sep = ",", header=T, fill = T) %>% mutate_all(as.character)

Raw_CGI_select$IMPROVEMENT<-as.numeric(Raw_CGI_select$IMPROVEMENT)

# Create treatment response binary variable
Raw_CGI_select$TXRESPONSE <- ifelse(is.na(Raw_CGI_select$IMPROVEMENT), NA, ifelse(Raw_CGI_select$IMPROVEMENT %in% c(1, 2, 3), 1, 0))
table(Raw_CGI_select$TXRESPONSE)

# Define the binary variable with labels
Raw_CGI_select$TXRESPONSE <- factor(Raw_CGI_select$TXRESPONSE, levels = c(0, 1), labels = c("Non-Responder", "Responder"))
table(Raw_CGI_select$TXRESPONSE)

#Run chi-square
contingency_table <- table(Raw_CGI_select$Condition, Raw_CGI_select$TXRESPONSE)
result <- chisq.test(contingency_table)
print(result)
print(contingency_table)

