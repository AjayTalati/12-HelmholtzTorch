-- Implement the wake-sleep algorithm, as in [1]
-- [1] Kirby, K. G. A Tutorial on Helmholtz s. Department of Computer Science, Northern Kentucky Unviersity, June 2006. http://citeseerx.ist.psu.edu/viewdoc/download?doi=10.1.1.112.7019&rep=rep1&type=pdf.

require 'torch'
require 'image'

do
   function Sigmoid(x) 
      return x:apply(function(x) return 1/(1+math.exp(-x)) end)
   --   x:mul(-1):exp():add(1):pow(-1)
   --  return x
   end

   function ExtendColumnByOne(x) 
      assert(x:size(2) == 1, 'not a column vector')
      x:resize(x:nElement()+1,1)
      x[x:nElement()] = 1
      return x
   end

   local Helmholtz = torch.class('Helmholtz')
   function Helmholtz:__init(nx, ny, nd, step)
      -- learning step
      self.step = step or 0.1
      -- dimensions of the layers
      self.nx = nx or 1
      self.ny = ny or 6
      self.nd = nd or 9
      -- generative distribution
      self.bG = torch.zeros(self.nx, 1)
      self.WG = torch.zeros(self.ny, self.nx+1)
      self.VG = torch.zeros(self.nd, self.ny+1)
      -- recognition distribution
      self.WR = torch.zeros(self.nx, self.ny+1)
      self.VR = torch.zeros(self.ny, self.nd+1)
   end

   function Helmholtz:Wake(d, step)
      step = step or self.step
      -- Experience reality!
      local d = ExtendColumnByOne(d)
      -- Pass sense datum up through recognition network
      local y = ExtendColumnByOne(
                Sigmoid(torch.mm(self.VR, d)):apply(torch.bernoulli)
            )
      local x = ExtendColumnByOne(
               Sigmoid(torch.mm(self.WR, y)):apply(torch.bernoulli)
            )

      -- Pass back down through generation network, saving computer probabilities
      local xi = Sigmoid(self.bG:clone())
      local psi = Sigmoid(torch.mm(self.WG, x))
      local delta = Sigmoid(torch.mm(self.VG, y))

      -- Adjust generative weights by delta rule 
      self.bG:add(step, x[{{1,self.nx}}] - xi)
      self.WG:addmm(step, (y[{{1,self.ny}}] - psi), x:t())
      self.VG:addmm(step, (d[{{1,self.nd}}] - delta), y:t())
   end

   function Helmholtz:Sleep(step)
      step = step or self.step
      -- Initiate a dream!
      local x = ExtendColumnByOne(
               Sigmoid(self.bG:clone()):apply(torch.bernoulli)
            )

      -- Pass dream signal down through generation network 
      local y = ExtendColumnByOne(
                Sigmoid(torch.mm(self.WG, x)):apply(torch.bernoulli)
            )
      local d = ExtendColumnByOne(
               Sigmoid(torch.mm(self.VG, y)):apply(torch.bernoulli)
            )

      -- Pass back up through recognition network, saving computer probabilities
      local psi = Sigmoid(torch.mm(self.VR, d))
      local xi = Sigmoid(torch.mm(self.WR, y))

      -- Adjust generative weights by delta rule 
      self.VR:addmm(step, (y[{{1,self.ny}}] - psi), d:t())
      self.WR:addmm(step, (x[{{1,self.nx}}] - xi), y:t())
   end

end
