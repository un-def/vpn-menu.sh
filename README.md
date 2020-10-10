# vpn-menu.sh

POSIX Shell script for toggling VPN connections using Rofi, dmenu or similar tool

## Dependencies

  * nmcli
  * awk
  * sed
  * sort
  * cut
  * wc
  * xargs

## Usage

See `vpn-menu.sh -h` for available options.

## Examples

  * use as Rofi modi:

    ```
    rofi -show vpn -modi vpn:'vpn-menu.sh --rofi'
    ```

  * use with dmenu, default settings (`dmenu -i -p VPN`):

    ```
    vpn-menu.sh --dmenu
    ```

  * use with dmenu, custom dmenu path/settings:

    ```
    vpn-menu.sh --dmenu /path/to/dmenu -b -nf green
    ```
