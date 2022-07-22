#!/usr/bin/env sh

sketchybar --animate sin 30 --set $NAME icon.highlight=$SELECTED background.drawing=$SELECTED
           icon.highlight=$SELECTED)
fi

if [ "$SELECTED" = "true" ]; then
  args+=(--set spaces_$DID.label label=${NAME#"spaces_$DID."} \
         --set $NAME icon.background.y_offset=-12              )
else
  args+=(--set $NAME icon.background.y_offset=-20)
fi

sketchybar -m --animate tanh 15 "${args[@]}"
