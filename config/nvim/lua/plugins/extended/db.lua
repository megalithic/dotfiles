return {
  { "tpope/vim-dadbod" },
  { "kristijanhusak/vim-dadbod-completion" },
  {
    "kristijanhusak/vim-dadbod-ui",
    config = function()
      vim.g.db_ui_save_location = vim.g.db_ui_path
      --
      -- delete from posts where id=18395898;

      -- delete pickups/items/friends
      -- delete from return_source;
      -- delete from return_authorizations;
      -- delete from notifications where method='sms';
      -- delete from items where pickup_id is NOT NULL;
      -- delete from route_steps where pickup_id is NOT NULL;
      -- delete from pickups;

      -- delete from eligible_locations where id in (2,3,4);
      -- delete from regions where id in (2);
      -- update zones set region_id=1 where id=2;

      -- select * from posts where service='omnivore' order by inserted_at DESC LIMIT 3;

      --select * from posts where service='omnivore' and (origin_url='' or title='') order by inserted_at DESC;

      --update posts set origin_url='https://www.wanderdc.com/best-family-day-trips-from-washington-dc/' where id=19387144;
      --update posts set contents='Washington, DC has so many thing to do for families with young adults and kids. However, sometimes its nice to get out of the nation’s capital to experience some of the best family-friendly day trips. There is something for everyone, from natural world sights to historic sites.' where id=19387144;
      --select * from posts where id=14902603;
      --update posts set tags='apartment,design' where id=17282497;

      -- select * from items where approval_status='approved';

      --delete from posts where origin_user='Thiago Ramos' and origin_url is NULL;
    end,
  },
}
