setwd("c:/Users/Work Station/Desktop/Data Analysis Projects/Datasets")

#Install Packages
install.packages("plyr")
install.packages("janitor")
install.packages("rfm")
install.packages("skimr")
install.packages("tidyverse")
install.packages("ggplot2")
install.packages("gganimate")
install.packages("tableHTML")
install.packages("treemap")

#Insalling libraries
library(readr)
library(rfm)
library(skimr)
library(ggplot2)
library(gganimate)  
library(janitor)
library(plyr)
library(lubridate)
library(dplyr)
library(knitr)
library(tableHTML)
library(treemap)



#Importing the dataset

retailsales <- read.csv("eCommerce Dataset - data.csv")

print(retailsales)

#Running summarises of the dataset 
colnames(retailsales)
glimpse(retailsales)
str(retailsales)
head(retailsales)
dim(retailsales)
summary(retailsales)

##Preprocessing

#Removing possible duplicates

retailsales2 <- unique(retailsales) 

#Noticed null values in the Customer ID column during exploration, removing them

is.na(retailsales2$CustomerID)
retailsales2 <- na.omit(retailsales2, select = c("CustomerID"))

#Converting the date column from character format to a date time format

retailsales2$InvoiceDate <- as.Date(retailsales2$InvoiceDate)

str(retailsales2$InvoiceDate) #Confirming the 'InvoiceDate' column has changed to date time format
glimpse(retailsales2$InvoiceDate)

#The cancelled order contain an 'InvoiceNo' that begins with a 'C', we won't be needing those for this analysis as our focus are our most valuable customers

retailsales2 <- retailsales2[!grepl("^C", retailsales2$InvoiceNo), ]
print(retailsales2$InvoiceNo)

#Dropping the 'StockCode,' and 'Description' column as they won't be necessary for the analysis

retailsales2 <- retailsales2 %>%  
  select(-c( StockCode,Description))


head(retailsales2)

##Exploratory data analysis 

#Calculating the revenue and including a revenue column

retailsales2$revenue <- retailsales2$Quantity * retailsales2$UnitPrice

print(retailsales2$revenue)

#Convert the revenue column to currency format

#retailsales2$revenue <- paste0("�", formatC(retailsales2$revenue, format = "f", digits = 2, big.mark = ","))
#glimpse(retailsales2$revenue)

#Extracting month from the 'InovoiceDate'column

retailsales2$month <- month.name[month(retailsales2$InvoiceDate)]
head(retailsales2)

#Checking for and removing null values in the 'month' column

is.na(retailsales2$month)
retailsales2 <- na.omit(retailsales2, select = c("month"))


#Visualising revenue over the months

# Convert the "month" column to a factor with the levels in the correct order
retailsales2$month <- factor(retailsales2$month, levels = month.name)

ggplot(retailsales2, aes(x = month, y = revenue)) +
  geom_bar(stat = "identity", fill = "steelblue") +
  labs(x = "Month", y = "Revenue", title = "Revenue by Month")+
  scale_y_continuous(labels = function(x) format(x, scientific = FALSE))  # Formatting y-axis labels



  # November is the month with the highest revenue, while February has the lowest contribution to revenue

#What is the average revenue per month?

retailsales_avg <- retailsales2 %>%
  group_by(month) %>%
  summarise(avgerage_revenue = mean(revenue))

print(retailsales_avg)

#November is the month with the highest average revenue, while June has the lowest. A very possible case of seasonality. 

#Top 5 countries contributing the most to revenue?

Top_Country <- retailsales2 %>%
  group_by(Country) %>%
  summarise(revenue = sum(revenue), avg_revenue = mean(revenue)) %>%
  ungroup() %>%
  arrange(desc(revenue)) %>%
  head(n = 5)
  print(Top_Country)

#Visualising the top 5 countries by revenue 
library(ggplot2)
ggplot(Top_Country, aes(x = "", y = revenue, fill = Country)) +
  geom_bar(width = 1, stat = "identity") +
  coord_polar(theta = "y") +
  labs(fill = "Country") +
  scale_fill_manual(values = my_colors, guide = "legend") +
  theme_void() +
  theme(legend.title = element_blank()) +
  theme(legend.position = "right") +
  guides(fill = guide_legend(title = "Country"))


## RFM Analysis

#Sidenote: 80% of business comes from 20% of customers

#Calculate RFM Metrics

#Calculate Recency, Frequency, and Monetary metrics

rfm_data <- retailsales2 %>%
  group_by(CustomerID) %>%
  summarise(
    Recency = difftime(max(InvoiceDate), max(InvoiceDate), units = "days"),
    Frequency = n_distinct(InvoiceNo),
    Monetary = sum(Quantity * UnitPrice)
  )

#RFM Score Calculation

rfm_data <- rfm_data %>%
  mutate(
    R_Score = ntile(Recency, 5),
    F_Score = ntile(Frequency, 5),
    M_Score = ntile(Monetary, 5),
    RFM_Score = paste0(R_Score, F_Score, M_Score)
  )

#Interpretation and Segmentation

rfm_data <- rfm_data %>%
  mutate(
    Segment = case_when(
      RFM_Score %in% c("555", "554", "544", "545") ~ "Best Customers",
      RFM_Score %in% c("535", "534", "525", "524") ~ "Loyal Customers",
      RFM_Score %in% c("515", "514", "504", "505") ~ "Potential Loyalists",
      RFM_Score %in% c("445", "444", "434", "435") ~ "Big Spenders",
      RFM_Score %in% c("425", "424", "415", "414") ~ "At Risk",
      RFM_Score %in% c("405", "404", "394", "395") ~ "Can't Lose Them",
      RFM_Score %in% c("345", "344", "334", "335") ~ "Almost Lost",
      RFM_Score %in% c("325", "324", "315", "314") ~ "Lost Customers",
      RFM_Score %in% c("305", "304", "294", "295") ~ "Lost Cheap Customers",
      TRUE ~ "Other"
    )
  )

#Visualizing the RFM segments
segment_counts <- rfm_data %>% count(Segment)
treemap(segment_counts, 
        index = "Segment", 
        vSize = "n", 
        title = "Customer Segments",
        border.col ='White',
        fontsize.labels = c(10, 8))
Print(segment_counts)

# Analyze the segments
segment_summary <- rfm_data %>%
  group_by(Segment) %>%
  summarise(
    Count = n(),
    Average_Monetary = mean(Monetary),
    Average_Recency = mean(Recency),
    Average_Frequency = mean(Frequency)
  )

# Print the segment summary
print(segment_summary)


