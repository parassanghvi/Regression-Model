# Regression-Model
######################################################

# STEP 1: START #

install.packages("gmodels")
install.packages("Hmisc")
install.packages("pROC")
install.packages("ResourceSelection")
install.packages("car")
install.packages("caret")
install.packages("dplyr")
library(gmodels)
library(Hmisc)
library(pROC)
library(ResourceSelection)
library(car)
library(caret)
library(dplyr)
install.packages("InformationValue")
library(InformationValue)

cat("\014") # Clearing the screen

# STEP 1: END #

# STEP 2: START #

# Setting the working directory - 
getwd()
setwd("C:/08072017/AMMA 2017/Data/data_2017/data_2017") #This working directory is the folder where all the bank data is stored

# reading client datasets
df.client <- read.csv('bank_client.csv')
str(df.client)

# reading other attributes
df.attr <- read.csv('bank_other_attributes.csv')
str(df.attr)

# reading campaign data
df.campaign <- read.csv('latest_campaign.csv')
str(df.campaign)

# reading campaign outcome
df.campOutcome <- read.csv('campaign_outcome.csv')
str(df.campOutcome)

# Create campaign data by joining all tables together
df.temp1 <- merge(df.client, df.campaign, by = 'Cust_id', all.x = TRUE)
df.temp2 <- merge(df.temp1, df.attr, by = 'Cust_id', all.x = TRUE)
df.data <- merge(df.temp2, df.campOutcome, by = 'Cust_id', all.x = TRUE)
length(unique(df.data$Cust_id)) == nrow(df.data) #checking for any duplicate customer ID

# clearing out temporary tables
rm(df.temp1,df.temp2)

# see few observations of merged dataset
head(df.data)

# STEP 2: END #

# STEP 3: START #

###### Rajneesh's Code Start ######

# see a quick summary view of the dataset
summary(df.data)

# see the tables structure
str(df.data)

# check the response rate
CrossTable(df.data$y)

# split the data into training and test
set.seed(1234) # for reproducibility
df.data$rand <- runif(nrow(df.data))
df.train <- df.data[df.data$rand <= 0.7,]
df.test <- df.data[df.data$rand > 0.7,]
nrow(df.train)
nrow(df.test)

# how the categorical variables are distributed and are related with target outcome
CrossTable(df.train$job, df.train$y)
CrossTable(df.train$marital, df.train$y)
CrossTable(df.train$education, df.train$y)
CrossTable(df.train$default, df.train$y)
CrossTable(df.train$housing, df.train$y)
CrossTable(df.train$loan, df.train$y)
CrossTable(df.train$poutcome, df.train$y)

# let see how the numerical variables are distributed
hist(df.train$age)
hist(df.train$balance)
hist(df.train$duration)
hist(df.train$campaign)
hist(df.train$pdays)
hist(df.train$previous)
describe(df.train[c("age", "balance", "duration", "campaign", "pdays", "previous")])

# running a full model  #

df.train$yact = ifelse(df.train$y == 'yes',1,0)
full.model <- glm(formula = yact ~ age + balance + duration + campaign + pdays + previous +
                    job + marital + education + default + housing + loan + poutcome, 
                  data=df.train, family = binomial)
summary(full.model)

# check for vif
fit <- lm(formula <- yact ~ age + balance + duration + campaign + pdays + previous +
            job + marital + education + default + housing + loan + poutcome, 
          data=df.train)
vif(fit)

# automated variable selection - Backward
backward <- step(full.model, direction = 'backward')
summary(backward)

# training probabilities and roc
df.train$prob = predict(full.model, type=c("response"))
class(df.train)
nrow(df.train)
q <- roc(y ~ prob, data = df.train)
plot(q)
auc(q)

# variable importance
varImp(full.model, scale = FALSE)

# confusion matrix on training set
df.train$ypred = ifelse(df.train$prob>=.5,'pred_yes','pred_no')
table(df.train$ypred,df.train$y)

#probabilities on test set
df.test$prob = predict(full.model, newdata = df.test, type=c("response"))

#confusion matrix on test set
df.test$ypred = ifelse(df.test$prob>=.5,'pred_yes','pred_no')
table(df.test$ypred,df.test$y)


#ks plot
ks_plot(actuals=df.train$y, predictedScores=df.train$ypred)

###### Rajneesh's Code End ######

# STEP 3: END #

########## K - code Start ##############

# STEP 4: START #

View(df.data)

# Loading df.data into df.data_final
df.data_final <- df.data
df.data_final$yact = ifelse(df.data$y == 'yes',1,0) #Loading 1s for 'yes' and 0s for 'no'
nrow(df.data_final)

#Removing every row with Not-Available entries
df.data_final <- df.data_final[!apply(df.data_final[,c("age", "balance", "duration", "campaign", "pdays", "previous", "job","marital", "education", "default", "housing", "loan", "poutcome")], 1, anyNA),]
nrow(df.data_final)
View(df.data_final)

set.seed(1234) # for reproducibility
df.data_final$rand <- runif(nrow(df.data_final))

#Training set = 90% of the entire data set #Test set = 10% of the entire data set
df.train_paras_model <- df.data_final[df.data_final$rand <= 0.9,]
df.test_paras_model <- df.data_final[df.data_final$rand > 0.9,]
nrow(df.train_paras_model)

#garbage collection to remove garbage from memory - to ensure memory overload doesn't happen
gc()

#Building a tentative model - with all the insignificant variables
result_tentative_trainparas_model <- glm(formula = yact ~ age + balance + duration + campaign + pdays + previous +
                                      job + marital + education + default + housing + loan + poutcome, 
                                    data=df.train_paras_model, family = binomial)
summary(result_tentative_trainparas_model)

# The process of removing insignificant variables one at a time based on their p-values
# removing insignificant variables - 1) job unknown removed
df.train_paras_model_onlysig <- df.train_paras_model[df.train_paras_model$job!="unknown",]
result_tentative_trainparas_model_sig1 <- glm(formula = yact ~ age + balance + duration + campaign + pdays + previous +
                                           job + marital + education + default + housing + loan + poutcome, 
                                         data=df.train_paras_model_onlysig, family = binomial)

df.test_paras_model_onlysig <- df.test_paras_model[df.test_paras_model$job!="unknown",]

summary(result_tentative_trainparas_model_sig1)

# removing insignificant variables - 2) pdays removed
df.train_paras_model_onlysig$pdays <-NULL
result_tentative_trainparas_model_sig1 <- glm(formula = yact ~ age + balance + duration + campaign + previous +
                                           job + marital + education + default + housing + loan + poutcome, 
                                         data=df.train_paras_model_onlysig, family = binomial)


df.test_paras_model_onlysig$pdays <-NULL

summary(result_tentative_trainparas_model_sig1)

# removing insignificant variables - 3) marital status 'single' removed
df.train_paras_model_onlysig <- df.train_paras_model_onlysig[df.train_paras_model_onlysig$marital!="single",]
result_tentative_trainparas_model_sig1 <- glm(formula = yact ~ age + balance + duration + campaign + previous +
                                           job + marital + education + default + housing + loan + poutcome, 
                                         data=df.train_paras_model_onlysig, family = binomial)

df.test_paras_model_onlysig <- df.test_paras_model_onlysig[df.test_paras_model_onlysig$marital!="single",]

summary(result_tentative_trainparas_model_sig1)

# removing insignificant variables - 4) removing default altogether (because it holds only one value throughout)
df.train_paras_model_onlysig <- df.train_paras_model_onlysig[df.train_paras_model_onlysig$marital!="yes",]
result_tentative_trainparas_model_sig1 <- glm(formula = yact ~ age + balance + duration + campaign + previous +
                                           job + marital + education + housing + loan + poutcome, 
                                         data=df.train_paras_model_onlysig, family = binomial)

df.test_paras_model_onlysig <- df.test_paras_model_onlysig[df.test_paras_model_onlysig$marital!="yes",]

summary(result_tentative_trainparas_model_sig1)

# removing insignificant variables - 5) removing job 'management'
df.train_paras_model_onlysig <- df.train_paras_model_onlysig[df.train_paras_model_onlysig$job!="management",]
result_tentative_trainparas_model_sig1 <- glm(formula = yact ~ age + balance + duration + campaign + previous +
                                           job + marital + education + housing + loan + poutcome, 
                                         data=df.train_paras_model_onlysig, family = binomial)

df.test_paras_model_onlysig <- df.test_paras_model_onlysig[df.test_paras_model_onlysig$job!="management",]

summary(result_tentative_trainparas_model_sig1)

# removing insignificant variables - 6) removing poutcome 'other'
df.train_paras_model_onlysig <- df.train_paras_model_onlysig[df.train_paras_model_onlysig$poutcome!="other",]
result_tentative_trainparas_model_sig1 <- glm(formula = yact ~ age + balance + duration + campaign + previous +
                                           job + marital + education + housing + loan + poutcome, 
                                         data=df.train_paras_model_onlysig, family = binomial)

df.test_paras_model_onlysig <- df.test_paras_model_onlysig[df.test_paras_model_onlysig$poutcome!="other",]

summary(result_tentative_trainparas_model_sig1)

# removing insignificant variables - 7) removing job 'entrepreneur'
df.train_paras_model_onlysig <- df.train_paras_model_onlysig[df.train_paras_model_onlysig$job!="entrepreneur",]
result_tentative_trainparas_model_sig1 <- glm(formula = yact ~ age + balance + duration + campaign + previous +
                                           job + marital + education + housing + loan + poutcome, 
                                         data=df.train_paras_model_onlysig, family = binomial)

df.test_paras_model_onlysig <- df.test_paras_model_onlysig[df.test_paras_model_onlysig$job!="entrepreneur",]

summary(result_tentative_trainparas_model_sig1)

# removing insignificant variables - 8) removing education 'unknown'
df.train_paras_model_onlysig <- df.train_paras_model_onlysig[df.train_paras_model_onlysig$education!="unknown",]
result_tentative_trainparas_model_sig1 <- glm(formula = yact ~ age + balance + duration + campaign + previous +
                                           job + marital + education + housing + loan + poutcome, 
                                         data=df.train_paras_model_onlysig, family = binomial)

df.test_paras_model_onlysig <- df.test_paras_model_onlysig[df.test_paras_model_onlysig$education!="unknown",]

summary(result_tentative_trainparas_model_sig1)

# removing insignificant variables - 9) removing job 'student'
df.train_paras_model_onlysig <- df.train_paras_model_onlysig[df.train_paras_model_onlysig$job!="student",]
result_tentative_trainparas_model_sig1 <- glm(formula = yact ~ age + balance + duration + campaign + previous +
                                           job + marital + education + housing + loan + poutcome, 
                                         data=df.train_paras_model_onlysig, family = binomial)

df.test_paras_model_onlysig <- df.test_paras_model_onlysig[df.test_paras_model_onlysig$job!="student",]

summary(result_tentative_trainparas_model_sig1)

# removing insignificant variables - 10) removing job 'unemployed'
df.train_paras_model_onlysig <- df.train_paras_model_onlysig[df.train_paras_model_onlysig$job!="unemployed",]
result_tentative_trainparas_model_sig1 <- glm(formula = yact ~ age + balance + duration + campaign + previous +
                                           job + marital + education + housing + loan + poutcome, 
                                         data=df.train_paras_model_onlysig, family = binomial)

df.test_paras_model_onlysig <- df.test_paras_model_onlysig[df.test_paras_model_onlysig$job!="unemployed",]

summary(result_tentative_trainparas_model_sig1)


#no more insignificant variables left. All independent variables left behind are significant.

#Loading the final model into result_paras_model_sig1
result_paras_model_sig1 <- result_tentative_trainparas_model_sig1
class(result_paras_model_sig1)
print(result_paras_model_sig1)
plot(result_paras_model_sig1)

# Variable importance #
plot(result_paras_model_sig1)
varImp(result_paras_model_sig1, scale = FALSE)
# Variable importance #

# Limitations of this model: Interactions are excluded; Linearity of independent variables is assumed #

fit_paras_model <- lm(formula <- yact ~ age + balance + duration + campaign + previous +
                   job + marital + education + housing + loan + poutcome, 
                 data=df.train_paras_model_onlysig)
vif(fit_paras_model)

# automated variable selection - Backward
backward_paras_model <- step(result_paras_model_sig1, direction = 'backward')
summary(backward_paras_model)

# training probabilities and roc
result_paras_model_probs <- df.train_paras_model_onlysig
nrow(result_paras_model_probs)
class(result_paras_model_probs)
#Using the model made to make predictions in the column named 'prob'
result_paras_model_probs$prob = predict(result_paras_model_sig1, type=c("response"))
q_paras_model <- roc(y ~ prob, data = result_paras_model_probs)
plot(q_paras_model)
auc(q_paras_model)

# how the categorical variables are distributed and are related with target outcome
CrossTable(df.train_paras_model_onlysig$job, df.train_paras_model_onlysig$y)
CrossTable(df.train_paras_model_onlysig$marital, df.train_paras_model_onlysig$y)
CrossTable(df.train_paras_model_onlysig$education, df.train_paras_model_onlysig$y)
CrossTable(df.train_paras_model_onlysig$default, df.train_paras_model_onlysig$y)
CrossTable(df.train_paras_model_onlysig$housing, df.train_paras_model_onlysig$y)
CrossTable(df.train_paras_model_onlysig$loan, df.train_paras_model_onlysig$y)
CrossTable(df.train_paras_model_onlysig$poutcome, df.train_paras_model_onlysig$y)

# numerical variable distribution
hist(df.train_paras_model_onlysig$age)
hist(df.train_paras_model_onlysig$balance)
hist(df.train_paras_model_onlysig$duration)
hist(df.train_paras_model_onlysig$campaign)
hist(df.train_paras_model_onlysig$previous)

# confusion matrix on paras-model training set
# to check the accuracy of the model made by removing all the insignificant variables
result_paras_model_probs$ypred = ifelse(result_paras_model_probs$prob>=.5,'pred_yes','pred_no')
table(result_paras_model_probs$ypred,result_paras_model_probs$y)

#probabilities on test set
df.test_paras_model_onlysig$prob = predict(result_paras_model_sig1, newdata = df.test_paras_model_onlysig, type=c("response"))

#confusion matrix on test set
df.test_paras_model_onlysig$ypred = ifelse(df.test_paras_model_onlysig$prob>=.5,'pred_yes','pred_no')
table(df.test_paras_model_onlysig$ypred,df.test_paras_model_onlysig$y)

# ks plot #
ks_plot(actuals=result_paras_model_probs$y, predictedScores=result_paras_model_probs$ypred)

# STEP 4: END

############### K - code End #############


# DO IT YOURSELF ------------------------------------------------------------------
# Improve your model by removing insignificant variables
# Use automated variable selection to improve models
# check performance of test data
#-------------------------------------------------------------------------------------
