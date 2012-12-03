require 'helmholtz'

function HashImage(d)
   local hash = 0
   local flat = d:resize(9,1)
   for i=1,9 do
      hash = hash*2 + flat[i][1]
   end
   return hash
end

function CountFreqs(d)
   local freqs = {}
   for i=1,d:size(1) do
      local h = HashImage(d[i])
      if freqs[h] == nil then
         freqs[h] = 1
      else
         freqs[h] = freqs[h] + 1
      end
   end
   for k,v in pairs(freqs) do
      freqs[k] = v/d:size(1)
   end
   return freqs
end

function SampleKirby()
   local d = torch.zeros(3,3)
   -- flip one column chosen with proba 1/3
   local col = torch.random(1,3)
   d[{{},col}] = 1
   -- transpose to horizontal with proba 1/3
   if torch.rand(1)[1] < .3 then d = d:t() end
   -- flip to white on black with proba 1/2
   if torch.rand(1)[1] < .5 then
      d:apply(function(x) return 1 - x end)
   end
   return d
end

function EstimateDistribution(sampler, N)
   N = N or 10000
   local d = torch.zeros(N,3,3)
   for i=1,N do
      d[i] = sampler()
   end

   local f = CountFreqs(d)
   return f
end

function PrintBest(d, Nbest)
   Nbest = Nbest or 20
   sorted = {}
   for _, v in pairs(d) do sorted[#sorted+1] = v end
   table.sort(sorted, function(a,b) return a > b end)
   for k, i in ipairs(sorted) do
      if k < Nbest then print(i) end
   end
   return sorted
end

function DemoKirby(T)
   T = T or 1000

--[[   print('* Displaying a few sample pictures')
   local N = 16
   local d = torch.zeros(N,3,3)
   for i=1,N do
      d[i] = SampleKirby()
   end
   image.display{image=d[{{1,16},{},{}}],zoom=30,padding=0} ]]

   print('* Counting a few sample pictures')
   f = EstimateDistribution(SampleKirby)
   PrintBest(f)

   h = Helmholtz()
   print('* Counting a few unlearned pictures')
   f = EstimateDistribution(function() return h:Sample() end)
   PrintBest(f)

   print('* Training ' .. T .. ' steps')
   for k = 1,T do
      d = SampleKirby()
      h:Wake(d:resize(9,1))
      h:Sleep()
      if math.mod(k,math.ceil(T/100)) == 0 then 
         io.write('.')
         io.flush()
      end
   end
   io.write('\n')

   print('* Counting a few unlearned pictures')
   f = EstimateDistribution(function() return h:Sample() end)
   PrintBest(f)

   return f
end
