function [count,bin] = BinByHour(Time,BinSize,BinEnd)

edges = 0:BinSize:BinEnd;
count =  histcounts(Time,edges)';
bin = edges(2:end) ./ BinSize;
bin = bin';