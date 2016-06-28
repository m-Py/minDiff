pckDIR <- "/home/martin/git/minDiff/"
myRlib <- "/home/martin/R/x86_64-pc-linux-gnu-library/3.3/"

library("roxyPackage")
roxy.package(
   pck.source.dir=pckDIR,
   pck.version="0.01-1",
   R.libs=myRlib,
   repo.root="~/R/repo/minDiff",
   pck.description=data.frame(
   Package="minDiff",
   Type="Minimize differences between groups",
   Title="",
   Author="Martin Papenberg <martin.papenberg@hhu.de>",
   AuthorsR="c(person(given=\"Martin\", family=\"Papenberg\",
   email=\"martin.papenberg@hhu.de\",
   role=c(\"aut\", \"cre\")))",
   Maintainer="Martin Papenberg <martin.papenberg@hhu.de>",
   Depends="R (>= 2.10.0)",
   Description="Assign any sort of elements to different groups and minimize group differences",
   License="GPL (>= 2)",
   Encoding="UTF-8",
   LazyLoad="yes",
   stringsAsFactors=FALSE)
)
