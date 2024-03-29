library(plyr)

read.CLAN.file <- function(f) {
  tmp <- readLines(f)
  print(f)
  #Cycle through utterances and make a line for each.
  alltext <- paste(tmp, collapse="\n")
  utts <- unlist(strsplit(alltext, "[*]"))
  utts <- utts[-1]
  tierlist <- sapply(utts, get_utt_info)
  data <- rbind.fill(tierlist)
  
  #Collect the data that will be appended to every line
  data$Filename <- f
  
  p <- grep("@Participants", tmp, fixed=TRUE)
  data$Participants <- unlist(strsplit(tmp[p], "\t"))[2]
  
  p <- grep("@Date", tmp, fixed=TRUE)
  data$Date <- unlist(strsplit(tmp[p], "\t"))[2]
  
  p <- grep("@Situation", tmp, fixed=TRUE)
  data$File.Situation <- unlist(strsplit(tmp[p], "\t"))[2]
  
  p <- grep("Target_Child", tmp, fixed=TRUE)
  chiline <- tmp[p[2]]
  chidata <- unlist(strsplit(chiline, "[|]"))
  data$Language <- substr(chidata[1], 6,9)
  data$Corpus <- chidata[2]
  data$Age <- chidata[4]
  data$Gender <- chidata[5]
  
  #Add utt line numbers
  data$Line.No 
  
  
  #Get rid of some yucky processing columns we don't want
  data$t.as.matrix.fields.. <- NULL
  xnums <- as.numeric(gsub("[^0-9]*[0-9]*[^0-9]*[0-9]*[^0-9]*[0-9]*[^0-9]+", "", names(data), perl=T)) 		# what a hack
  for(x in min(xnums, na.rm=T):max(xnums, na.rm=T)) {
    xname <- paste("X", x, sep="")
    data <- data[,!(names(data) %in% xname)]
    
  }
  
  #Make sure row names are preserved!
  data$Utt.Number <- row.names(data)
  
  #Return
  data
} #End read.CLAN.file

get_utt_info <- function(u){
  
  #Divide the line into individual utterances & tiers
  fields <- unlist(strsplit(u, "[%]"))
  #Make a dataframe
  myrow <- data.frame(t(as.matrix(fields)))
  
  #Add utterance info
  myrow$Speaker <- substr(fields[1], 1,3)
  myrow$Verbatim <- substr(fields[1], 6,nchar(fields[1])-1)
  
  #Add info from any tiers, as they appear in the file
  if (length(fields) > 1){
    for (j in 2:length(fields)){
      tier <- data.frame(substr(fields[j], 6,nchar(fields[j])-1))
      names(tier) <- c(substr(fields[j], 1,3))
      myrow <- cbind(myrow, tier)
    }
  }
  
  #Some extra work: get the line as spoken, with glosses replaced
  #...This is an adult-language, human-readable version of the utterance
  
  myrow$Gloss <- NA
  #First, find & replace sequences like this: "dunno [: don't know]" -> "don't know"
  words <- unlist(strsplit(myrow$Verbatim, " "))
  if (length(words) == 0){
    words <- c("")
  }
  
  words <- unlist(strsplit(words, "\t"))
  if (length(words) == 0){
    words <- c("")
  }
  
  words <- unlist(strsplit(words, "\n"))
  if (length(words) == 0){
    words <- c("")
  }
  
  w <- 1
  wmax <- length(words) + 1
  while (w < wmax){
    #Did we hit a gloss sequence?
    if ((words[w]=="[:")|(words[w]=="[=?")){
      #Find where the gloss ends, then clean up
      closebracket <- grep("]",  words[w:length(words)], fixed=TRUE)[1] + (w-1)
      words[w-1] <- ""
      words[w] <- ""
      words[closebracket] <- substr(words[closebracket], 1, nchar(words[closebracket])-1)
    }
    w <- w + 1	
  }
  
  #Next, find & replace clarification/elaboration sequences like this: "a bobby [= a thin bobbypin]" -> "a bobby"
  w <- 1
  wmax <- length(words) + 1
  while (w < wmax){
    #Did we hit a gloss sequence?
    if ((substr(words[w],1,1) == "[")){
      #Find where the gloss ends, then clean up
      closebracket <- grep("]",  words[w:length(words)], fixed=TRUE)[1] + (w-1)
      goo <- closebracket
      for (v in w:closebracket){
        words[v] <- ""
      }
    }
    w <- w + 1	
  }
  
  #Next, delete internal notation we don't need here
  words <- as.vector(mapply(gsub, "[()<>&@:]","",words))
  
  #Remove sentence-internal periods!
  words[1:(length(words)-1)] <- as.vector(mapply(gsub, "[.]","",words[1:(length(words)-1)]))
  
  myrow$Gloss <- paste(words, collapse=" ")
  myrow$Gloss <- gsub(" +", " ", myrow$Gloss)
  
  #Return
  myrow
  
} #END get_utt_info