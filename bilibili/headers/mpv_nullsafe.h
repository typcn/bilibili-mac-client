//
//  mpv_nullsafe.h
//  bilibili
//
//  Created by TYPCN on 2016/3/7.
//  Copyright © 2016 TYPCN. All rights reserved.
//

#ifndef mpv_nullsafe_h
#define mpv_nullsafe_h

#define mpv_command if(!self.player.mpv){return;} mpv_command
#define mpv_command_async if(!self.player.mpv){return;} mpv_command_async
#define mpv_set_property_async if(!self.player.mpv){return;} mpv_set_property_async
#define mpv_set_property if(!self.player.mpv){return;} mpv_set_property
#define mpv_get_property_async if(!self.player.mpv){return;} mpv_get_property_async
#define mpv_get_property if(!self.player.mpv){return;} mpv_set_property

#endif /* mpv_nullsafe_h */
