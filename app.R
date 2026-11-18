# Author: Guoli XI

#Load packages for shiny web app
library(shiny)
library(data.table)
library(ggplot2)
library(DT)

#Check rds file, read data, set plot theme, make selectable features.
if (!file.exists("outputs/dashboard_data.rds")) stop("Run source('render.R') before launching the app.")
b <- readRDS("outputs/dashboard_data.rds")
theme_set(theme_minimal(base_size=12))
feature_choices <- c("mean_price","relative_mean","price_sd","mean_abs_change","increase_rate")

#Make UI page
ui <- fluidPage(
 tags$head(tags$style(HTML("
 body{background:#f4f7f9;color:#193d4b;font-family:Arial,sans-serif}
 .container-fluid{max-width:1450px}
 .hero{background:#173d50;color:white;padding:28px 32px;border-radius:12px;margin:18px 0}
 .hero h1{font-size:32px;margin:0 0 8px}.hero p{color:#d7e7ec;margin:0}
 .well{background:white;border:1px solid #dce5e9;border-radius:10px}
 .tab-content{background:white;padding:22px;border:1px solid #dce5e9;border-top:0}
 .scope{color:#526a76;font-size:14px;margin:12px 0 20px}
 .metric{padding:18px;background:#eef5f6;border-radius:9px;margin-bottom:18px}
 .metric .shiny-text-output{display:block;font-size:26px;color:#167c80}
 .nav-tabs>li>a{color:#173d50}
 "))),

#Add some blocks
 div(class="hero",h1("FuelWatch WA"),p("Explore local fuel prices • January 2023–August 2026")),
 
#Build Explore tab with filters, histogram bin slider, download button, value boxes and multiple plots plus data table.
 tabsetPanel(id="tabs",
  tabPanel("Explore",
   p(class="scope","Filters on this tab affect the exploration charts only. Prices are notified cents per litre, not sales-weighted."),
   sidebarLayout(
    sidebarPanel(width=3,
     selectInput("product","Fuel product",choices=sort(unique(b$monthly$product)),selected="ULP",selectize=FALSE),
     selectInput("region","Region",choices=c("All regions",sort(unique(b$monthly$region))),selectize=FALSE),
     dateRangeInput("dates","Period",start=min(b$daily$date),end=max(b$daily$date),
                    min=min(b$daily$date),max=max(b$daily$date)),
     sliderInput("bins","Histogram bins",min=10,max=80,value=35),
     helpText("Trend and brand summaries use all records in the selected scope. Distribution uses a fixed plotting sample."),
     downloadButton("download_summary","Download daily summary")),
    mainPanel(width=9,
     fluidRow(column(4,div(class="metric",textOutput("mean_price"),span("Mean price (c/L)"))),
              column(4,div(class="metric",textOutput("record_count"),span("Notified records"))),
              column(4,div(class="metric",textOutput("day_count"),span("Observed days")))),
     plotOutput("trend",height=310),
     fluidRow(column(6,plotOutput("distribution",height=300)),
              column(6,plotOutput("brands",height=300))),
     p(class="scope","Brand chart uses complete selected calendar months only; date boundaries are rounded inward. This differs from the exact-date trend if you choose partial months."),
     DTOutput("summary_table"))
   )),
  
#Create Relationships tab
  tabPanel("Relationships",
   p(class="scope","Multi-variable views. Site features are ULP site profiles from May–July 2026 (one point per site). The brand chart uses pre-test ULP records with the cheap/expensive label."),
   sidebarLayout(
    sidebarPanel(width=3,
     selectInput("plot_type","Plot type",c("Scatter","Pairwise","2D bins","Cheap share by brand"),selectize=FALSE),
     conditionalPanel("input.plot_type == 'Pairwise'",
      checkboxGroupInput("pair_vars","Site features",choices=feature_choices,selected=feature_choices[-1])),
     conditionalPanel("input.plot_type == 'Scatter' || input.plot_type == '2D bins'",
      selectInput("x_attr","x-axis",feature_choices,selected="mean_abs_change",selectize=FALSE),
      selectInput("y_attr","y-axis",feature_choices,selected="increase_rate",selectize=FALSE)),
     conditionalPanel("input.plot_type == 'Scatter'",
      sliderInput("alpha","Point transparency (alpha)",min=.05,max=1,value=.5,step=.05),
      checkboxInput("smooth","Add smoothed line",TRUE)),
     conditionalPanel("input.plot_type == 'Cheap share by brand'",
      selectInput("rel_region","Region",c("All regions",sort(unique(b$target_brand$region))),selectize=FALSE),
      radioButtons("bar_position","Bar type",c(Filled="fill",Stacked="stack","Side by side"="dodge")))),
    mainPanel(width=9,plotOutput("relationship",height=480),
     p(class="scope","Teal = Metro and Peel, orange = regional WA. Metro sites move price often and by large amounts; regional sites barely move. Of brand, region and calendar, brand is the strongest single predictor of a cheap record; a station's own cheap history is stronger still."))
   )),
  

#Create Classification tab
  tabPanel("Classification",
   p(class="scope","Fixed evaluation: ULP in August 2026. Cheap means below the same-day regional median; ties are expensive. Exploration filters do not change these results."),
   fluidRow(column(4,selectInput("strategy","Training strategy",c("Historical","Recent"),selectize=FALSE)),
            column(4,selectInput("split","Evaluation split",c("Test","Calibration","Train"),selectize=FALSE))),
   p("Historical: August 2023–2025. Recent: May–July 2026. Within each source month, a random quarter of the dates validate and the other dates train. Both strategies use the same number of training rows; Naive Bayes uses all of them and the SVM a 4,000-row subsample. Predictors are brand, region, weekday, day-of-month and site history (each station's cheap rate in the training rows only)."),
   plotOutput("model_scores",height=310),
   fluidRow(column(6,plotOutput("roc",height=320)),
            column(6,tableOutput("confusion"))),
   DTOutput("metrics"),
   h4("Selected models"),tableOutput("selected"),
   h4("Recent minus historical test AUC"),tableOutput("bootstrap"),
   p(class="scope","AUC ranks cheap records; F1 and balanced accuracy evaluate the fixed 0.5 cutoff. Higher complexity is useful only if it improves on both baselines. Bootstrap intervals resample test dates and are descriptive.")),
  tabPanel("Site clusters",
   p(class="scope","ULP site profiles from May–July 2026, with at least 60 days. Features are standardised before clustering. Exploration filters do not apply."),
   fluidRow(column(4,selectInput("k","Number of clusters",choices=as.character(b$cluster_scores$k),
                                selected=as.character(b$best_k),selectize=FALSE))),
   fluidRow(column(7,plotOutput("clusters",height=350)),
            column(5,plotOutput("k_scores",height=350))),
   tableOutput("cluster_profile"),
   DTOutput("site_table"),
   p(class="scope","Cluster numbers are arbitrary labels. PCA is a two-dimensional projection of the retained features. See the report for correlation filtering and Manhattan/PAM sensitivity.")),
  
#Build Data and method tab
  tabPanel("Data and method",
   h3("What this dashboard measures"),
   p("One record is a site-product-date notified price. Averages weight records equally. Changing reporting coverage can affect trends. The data do not establish causal effects of war or other external events."),
   h4("Cleaning audit"),tableOutput("quality"),
   h4("Monthly coverage"),plotOutput("coverage",height=300),
   h4("Input manifest"),DTOutput("manifest"),
   p("Source: FuelWatch monthly CSV files from https://www.fuelwatch.wa.gov.au/retail/historic, downloaded on 25 September 2026. September 2026 is excluded."),
   p("To rebuild: run setup.R once, then render.R. The report creates this dashboard bundle."),
   p(paste("Bundle generated:",format(b$created,"%Y-%m-%d %H:%M"))))
 )
)

#Filter daily fuel data based on user choices.
server <- function(input,output,session) {
 selected_daily <- reactive({
   req(input$dates,input$product,input$region)
   x <- b$daily[product==input$product & date>=input$dates[1] & date<=input$dates[2]]
   if (input$region!="All regions") x <- x[region==input$region]
   validate(need(nrow(x)>0,"No records for these filters. Try another product or date range."))
   x
 })

#Calculate daily average price. Show summary numbers and draw price trend line chart.
 trend_data <- reactive({
   selected_daily()[,.(mean_price=weighted.mean(mean_price,records),records=sum(records)),by=date][order(date)]
 })
 output$mean_price <- renderText(sprintf("%.1f",weighted.mean(selected_daily()$mean_price,selected_daily()$records)))
 output$record_count <- renderText(format(sum(selected_daily()$records),big.mark=","))
 output$day_count <- renderText(as.character(uniqueN(selected_daily()$date)))
 output$trend <- renderPlot({
   ggplot(trend_data(),aes(date,mean_price))+geom_line(colour="#167c80",linewidth=.7)+
    labs(title=paste(input$product,"daily average"),x=NULL,y="Price (c/L)")
 })


#Filter plot sample data
 output$distribution <- renderPlot({
   x <- b$plot_sample[product==input$product & date>=input$dates[1] & date<=input$dates[2]]
   if(input$region!="All regions") x <- x[region==input$region]
   validate(need(nrow(x)>0,"No plotting-sample records for this scope."))
   ggplot(x,aes(price))+geom_histogram(bins=input$bins,fill="#167c80",colour="white")+
    labs(title="Price distribution (sample)",x="Price (c/L)",y="Sample records")
 })

#Filter brand data, compute average price per brand and save top 12 brands.
 brand_data <- reactive({
   req(input$dates)
   lo <- as.Date(input$dates[1]); hi <- as.Date(input$dates[2])
   x <- copy(b$brand_month[product==input$product])
   x[,month_end:=as.Date(format(month_date+32,"%Y-%m-01"))-1]
   x <- x[month_date>=lo & month_end<=hi]
   if(input$region!="All regions") x<-x[region==input$region]
   validate(need(nrow(x)>0,"Select at least one complete calendar month for brand comparison."))
   x[,.(mean_price=weighted.mean(mean_price,records),records=sum(records)),by=brand][order(-records)][1:min(.N,12)]
 })

#Draw horizontal bar chart to show average price of top brands.
 output$brands <- renderPlot({
   ggplot(brand_data(),aes(reorder(brand,mean_price),mean_price))+
    geom_col(fill="#c36b39")+coord_flip()+
    labs(title="12 most-observed brands",x=NULL,y="Mean price (c/L)")
 })

#Make interactive data table for daily price
 output$summary_table <- renderDT({
   datatable(trend_data(),rownames=FALSE,options=list(pageLength=7,scrollX=TRUE)) |>
     formatRound("mean_price",2)
 })

#Add download data button
 output$download_summary <- downloadHandler(
   filename=function() paste0("fuelwatch-",input$product,"-daily.csv"),
   content=function(file) fwrite(trend_data(),file))

#Draw different types of charts based on user selected
 output$relationship <- renderPlot({
   x <- copy(b$profiles)
   x[,area:=ifelse(region %in% c("METRO","PEEL"),"Metro and Peel","Regional WA")]
   area_colours <- c("Metro and Peel"="#167c80","Regional WA"="#c36b39")
   if (input$plot_type=="Pairwise") {
     validate(need(length(input$pair_vars)>=2,"Choose at least two features."))
     pairs(x[,input$pair_vars,with=FALSE],col=area_colours[x$area],pch=20,cex=.7)
   } else if (input$plot_type=="Scatter") {
     g <- ggplot(x,aes(.data[[input$x_attr]],.data[[input$y_attr]],colour=area))+
       geom_point(alpha=input$alpha,size=2)+scale_colour_manual(values=area_colours)
     if (input$smooth) g <- g+geom_smooth(method="loess",formula=y~x,se=FALSE)
     g+labs(title=paste(input$y_attr,"vs",input$x_attr),x=input$x_attr,y=input$y_attr,colour=NULL)
   } else if (input$plot_type=="2D bins") {
     ggplot(x,aes(.data[[input$x_attr]],.data[[input$y_attr]]))+geom_bin2d(bins=30)+
       scale_fill_gradient(low="#d7e7ec",high="#173d50")+
       labs(title="2D histogram of sites",x=input$x_attr,y=input$y_attr,fill="Sites")
   } else {
     z <- b$target_brand
     if (input$rel_region!="All regions") z <- z[region==input$rel_region]
     validate(need(nrow(z)>0,"No records for this region."))
     top <- z[,.(n=sum(N)),by=brand][order(-n)][1:min(.N,12),brand]
     z <- z[brand %in% top]
     ggplot(z,aes(y=reorder(brand,N,sum),weight=N,fill=target))+
       geom_bar(position=input$bar_position)+
       scale_fill_manual(values=c(expensive="#c36b39",cheap="#167c80"))+
       labs(title="Cheap and expensive ULP records by brand",x=if (input$bar_position=="fill") "Share" else "Records",
            y=NULL,fill="Target")
   }
 })

#Filter model evaluation metrics
 chosen_metrics <- reactive(b$evaluation[strategy==input$strategy & split==input$split])
 output$model_scores <- renderPlot({
   z <- melt(chosen_metrics(),id.vars="model",measure.vars=c("AUC","F1","Balanced_accuracy"))
   ggplot(z,aes(model,value,fill=variable))+geom_col(position="dodge")+
    coord_cartesian(ylim=c(0,1))+scale_fill_manual(values=c("#167c80","#c36b39","#5479a3"))+
    labs(title=paste(input$strategy,input$split,"performance"),x=NULL,y="Score",fill="Metric")
 })

#Draw ROC curve plot
 output$roc <- renderPlot({
   ggplot(b$roc[strategy==input$strategy],aes(FPR,TPR,colour=model))+
    geom_line(linewidth=.8)+geom_abline(slope=1,intercept=0,linetype=2)+coord_equal()+
    labs(title="August 2026 test ROC (always test)",x="False-positive rate",y="True-positive rate")
 })

#Output confusion matrix table
 output$confusion <- renderTable({
   chosen_metrics()[,.(Model=model,TP,FP,FN,TN)]
 },striped=TRUE)

#Create interactive table of model metrics
 output$metrics <- renderDT({
   datatable(chosen_metrics()[,.(model,n,Accuracy,Precision,Recall,Specificity,F1,Balanced_accuracy,AUC)],
             rownames=FALSE,options=list(dom="t",scrollX=TRUE)) |>
    formatRound(c("Accuracy","Precision","Recall","Specificity","F1","Balanced_accuracy","AUC"),3)
 })

#Render tables
 output$selected <- renderTable(b$selected[strategy==input$strategy,
                             .(method,features,cost,gamma,calibration_AUC=AUC)],digits=3)
 output$bootstrap <- renderTable(b$bootstrap,digits=3)
 selected_profiles <- reactive({
   x <- copy(b$profiles)
   x[,cluster:=factor(b$cluster_assignments[[input$k]])]
   x
 })

#Draw scatter plot, different cluster group has different color
 output$clusters <- renderPlot({
   ggplot(selected_profiles(),aes(PC1,PC2,colour=cluster))+geom_point(alpha=.8,size=2)+
    labs(title=paste("Site profiles — k =",input$k),x="PC1",y="PC2",colour="Cluster")
 })

#Draw plot silhouette scores for different k values
 output$k_scores <- renderPlot({
   ggplot(b$cluster_scores,aes(k,silhouette))+geom_line(colour="#167c80")+geom_point(size=3)+
    geom_vline(xintercept=as.integer(input$k),linetype=2,colour="#c36b39")+
    labs(title="Cluster separation",x="k",y="Mean silhouette")
 })

#Calculate stats for each cluster group and make a summary table for site groups.
 output$cluster_profile <- renderTable({
   selected_profiles()[,.(sites=.N,mean_price=mean(mean_price),
      relative_mean=mean(relative_mean),price_sd=mean(price_sd),
      mean_abs_change=mean(mean_abs_change),increase_rate=mean(increase_rate)),by=cluster]
 },digits=2)

#Make interactive table to show site info
 output$site_table <- renderDT({
   datatable(selected_profiles()[,.(site_name,brand,region,days,cluster,mean_price,relative_mean)],
       rownames=FALSE,options=list(pageLength=8,scrollX=TRUE)) |>
      formatRound(c("mean_price","relative_mean"),2)
 })

#Show a quality information table
 output$quality <- renderTable(b$quality)

#Show how many fuel sites are recorded each month.
 output$coverage <- renderPlot({
   ggplot(b$coverage,aes(month_date,sites))+geom_line(colour="#167c80")+
    labs(title="Observed ULP sites per month",x=NULL,y="Sites")
 })

#Make a table showing a summary of each raw data
 output$manifest <- renderDT({
   datatable(b$manifest[,.(source_file,rows,first,last,days,complete,md5)],rownames=FALSE,
             options=list(pageLength=8,scrollX=TRUE))
 })
}


shinyApp(ui,server)


