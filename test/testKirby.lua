require 'demoKirby'

mytest = {}
tester = torch.Tester()

function mytest.TestKirbyGeneration()
   local d = SampleKirby(1)
   tester:asserteq(d:dim(), 2, 'not large enough')
   tester:asserteq(d:size(1), 3, 'not 3 rows')
   tester:asserteq(d:size(2), 3, 'not 3 columns')
   -- do no test frequencies, since they are random --
end

function mytest.TestCountFreqs()
   local d = torch.zeros(2,3,3)
   local f = CountFreqs(d)
   for k,v in pairs(f) do
      tester:asserteq(k, HashImage(torch.zeros(3,3)), 'stored another key than zeros')
      tester:asserteq(v, 2, 'counted  ' .. v .. ' not 2')
  end
end

function mytest.TestKeying()
   local keyOnAddress = {}
   local keyOnValue = {}
   local k1 = {1, 2, 3}
   local k2 = {1, 2, 3}
   
   -- Using the object as a key: the reference is used
   keyOnAddress[k1] = 1
         keyOnAddress[k2] = 3
   tester:assert(keyOnAddress[k1] ~= keyOnAddress[k2], 'accessed values based on key contents, not key address')

   -- Using a hash function as a key
   function hash(k) return k[1] + k[2] + k[3] end
   keyOnValue[hash(k1)] = 1
   keyOnValue[hash(k2)] = 3
   tester:assert(keyOnAddress[hash(k1)] == keyOnAddress[hash(k2)], 'accessed values based on key address, not hash value')

end

tester:add(mytest)
tester:run()