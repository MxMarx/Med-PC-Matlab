function [count,bin] = BinByHour(Time,BinSize)

edges = 0:BinSize:21600;
count =  histcounts(Time,edges)';
bin = edges(2:end) ./ BinSize;
bin = bin';