SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
PDPANEL_ID=$(xdotool search --name "PDPanel")
$SCRIPT_DIR/sty -w $PDPANEL_ID -f "TELETYPE 1945\\-1985" -t "PDP-10 Console Teletype" telnet localhost 1025
