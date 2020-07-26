# Horizon-Scripts
Use of these scripts are shown in the video listed here: https://www.youtube.com/watch?v=S9jIZwxAj3A
The two scripts in this repo are used in conjunction with Windows Task Manager to schedule and unschedule desktop pool entitlements for VMware Horizon 7. 
The first script entitles Active Directory groups to desktop pools
The second script should be scheduled to trigger 15 minutes before the end of the scheduled session and sends a warning message 15 minutes before session end and then again at 5 minutes before automatically loggin the user off and removing the pool entitlements
