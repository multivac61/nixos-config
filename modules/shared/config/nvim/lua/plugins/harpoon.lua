return {
    "ThePrimeagen/harpoon",
    branch = "harpoon2",
		-- stylua: ignore
		keys = {
			{ '<leader>ua', 'ga', desc = 'Show character under cursor' },
			{ 'ga', function() require('harpoon'):list():append() end, desc = 'Add location' },
			{ '<C-n>', function() require('harpoon'):list():next() end, desc = 'Next location' },
			{ '<C-p>', function() require('harpoon'):list():prev() end, desc = 'Previous location' },
			{ '<leader>mr', function() require('harpoon'):list():remove() end, desc = 'Remove location' },
			{ '<leader>1', function() require('harpoon'):list():select(1) end, desc = 'Harpoon select 1' },
			{ '<leader>2', function() require('harpoon'):list():select(2) end, desc = 'Harpoon select 2' },
			{ '<leader>3', function() require('harpoon'):list():select(3) end, desc = 'Harpoon select 3' },
			{ '<leader>4', function() require('harpoon'):list():select(4) end, desc = 'Harpoon select 4' },
			{ '<leader>5', function() require('harpoon'):list():select(5) end, desc = 'Harpoon select 5' },
			{ '<leader>l', function() return require('telescope._extensions.marks')() end, desc = 'List locations' },
  },
}