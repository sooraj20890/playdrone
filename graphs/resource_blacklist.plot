set terminal pdf dashed size 4.5,2
set output "resource_blacklist.pdf"

#set title "Resource Blacklist size VS Cutoff (log scale)\n(a resource is blacklisted iif at least C apps share the resource)"
#set key reverse Left outside

set ylabel "Number of \n Blacklisted Resources" offset +1, 0
set xlabel "C = Blacklist Cutoff" offset 0,+0.2
set grid

set logscale xy
set grid xtics ytics lt 0 lw 1 lc rgb "#888888"

#set xtics (10, 100, 300, 1000, 10000, 100000, 1000000, 10000000)
set mxtics (10)

set pointsize 0.5

set arrow from 300,1 to 300,1000000 nohead lc 2 lw 3
set label "300" at 210, 0.3

plot 'resource_blacklist.dat' using 1:2 lt 1 lc 1 lw 3 pt 1 with linespoints t "Resource Names", \
                           '' using 1:3 lt 1 lc 3 lw 3 pt 2 with linespoints t "Asset Hashes"
