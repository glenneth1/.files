return {
  'hamidi-dev/org-super-agenda.nvim',
  dependencies = {
    'nvim-orgmode/orgmode', -- required
    { 'lukas-reineke/headlines.nvim', config = true }, -- optional nicety
  },
  config = function()
    require('org-super-agenda').setup({
      -- Where to look for .org files
      org_files           = {},
      org_directories     = {},
      exclude_files       = {},
      exclude_directories = {},

      -- TODO states + their quick filter keymaps and highlighting
      todo_states = {
        { name='TODO',     keymap='ot', color='#FF5555', strike_through=false, fields={'filename','todo','headline','priority','date','tags'} },
        { name='PROGRESS', keymap='op', color='#FFAA00', strike_through=false, fields={'filename','todo','headline','priority','date','tags'} },
        { name='WAITING',  keymap='ow', color='#BD93F9', strike_through=false, fields={'filename','todo','headline','priority','date','tags'} },
        { name='DONE',     keymap='od', color='#50FA7B', strike_through=true,  fields={'filename','todo','headline','priority','date','tags'} },
      },

      -- Agenda keymaps
      keymaps = {
        filter_reset      = 'oa',
        toggle_other      = 'oo',
        filter            = 'of',
        filter_fuzzy      = 'oz',
        filter_query      = 'oq',
        undo              = 'u',
        reschedule        = 'cs',
        set_deadline      = 'cd',
        cycle_todo        = 't',
        set_state         = 's',
        reload            = 'r',
        refile            = 'R',
        hide_item         = 'x',
        preview           = 'K',
        clock_in          = 'I',
        clock_out         = 'O',
        clock_cancel      = 'X',
        clock_goto        = 'gI',
        reset_hidden      = 'gX',
        fold_all          = 'zM',
        unfold_all        = 'zR',
        toggle_duplicates = 'D',
        cycle_view        = 'ov',
        bulk_mark         = 'm',
        bulk_unmark_all   = 'M',
        bulk_reselect     = 'gv',
        bulk_action       = 'B',
        open_view         = 'V',
      },

      -- Window/appearance
      window = {
        width        = 0.8,
        height       = 0.7,
        border       = 'rounded',
        title        = 'Org Super Agenda',
        title_pos    = 'center',
        margin_left  = 0,
        margin_right = 0,
        fullscreen_border = 'none',
      },

      -- Group definitions (order matters; first match wins unless allow_duplicates=true)
      groups = {
        { name = '📅 Today',     matcher = function(i) return i.scheduled and i.scheduled:is_today() end, sort={ by='scheduled_time', order='asc' } },
        { name = '🗓️ Tomorrow', matcher = function(i) return i.scheduled and i.scheduled:days_from_today() == 1 end, sort={ by='scheduled_time', order='asc' } },
        { name = '☠️ Deadlines', matcher = function(i) return i.deadline and i.todo_state ~= 'DONE' and not i:has_tag('personal') end, sort={ by='deadline', order='asc' } },
        { name = '⭐ Important',  matcher = function(i) return i.priority == 'A' and (i.deadline or i.scheduled) end, sort={ by='date_nearest', order='asc' } },
        { name = '⏳ Overdue',    matcher = function(i) return i.todo_state ~= 'DONE' and ((i.deadline and i.deadline:is_past()) or (i.scheduled and i.scheduled:is_past())) end, sort={ by='date_nearest', order='asc' } },
        { name = '🏠 Personal',   matcher = function(i) return i:has_tag('personal') end },
        { name = '💼 Work',       matcher = function(i) return i:has_tag('work') end },
        { name = '📆 Upcoming',   matcher = function(i)
            local days = require('org-super-agenda.config').get().upcoming_days or 10
            local d1 = i.deadline  and i.deadline:days_from_today()
            local d2 = i.scheduled and i.scheduled:days_from_today()
            return (d1 and d1 >= 0 and d1 <= days) or (d2 and d2 >= 0 and d2 <= days)
          end,
          sort={ by='date_nearest', order='asc' }
        },
      },

      -- Defaults & behavior
      upcoming_days      = 10,
      hide_empty_groups  = true,
      keep_order         = false,
      allow_duplicates   = false,
      group_format       = '* %s',
      other_group_name   = 'Other',
      show_other_group   = false,
      show_tags          = true,
      show_filename      = true,
      heading_max_length = 70,
      persist_hidden     = false,
      view_mode          = 'classic',

      classic = { heading_order={'filename','todo','priority','headline'}, short_date_labels=false, inline_dates=true },
      compact = { filename_min_width=10, label_min_width=12 },

      group_sort = { by='date_nearest', order='asc' },

      popup_mode = {
        enabled      = vim.env.ORG_SUPER_AGENDA_POPUP == '1',
        hide_command = 'tmux detach-client',
      },

      debug = false,

      custom_views = {},
    })
  end,
}
