use str
use re

fn -shell-var [line]{
  index = (str:index $line '=')

  if (== $index -1) {
    fail 'invalid shell variable assignment'
  }

  put [
    &name=(str:trim-space $line[..$index])
    &value=(str:trim-space $line[(+ $index 1)..])
  ]
}

fn window [id]{
  name _ x y width height screen = (e:xdotool getwindowname $id getwindowgeometry --shell $id)

  put [
    &name=$name
    &id=$id
    &screen=(num (-shell-var $screen)[value])
    &x=(num (-shell-var $x)[value])
    &y=(num (-shell-var $y)[value])
    &width=(num (-shell-var $width)[value])
    &height=(num (-shell-var $height)[value])
  ]
}

fn active-window []{
  window (e:xdotool getactivewindow)
}

fn monitors []{
  e:xrandr --query | each [a]{
    if (str:contains $a 'connected') {
      monitor = [
        &name=$a[0..(str:index $a ' ')]
        &connected=(not (str:contains $a 'disconnected'))
        &primary=(str:contains $a 'primary')
      ]

      if $monitor[connected] {
        mode = (re:find &max=1 '(\d+)x(\d+)\+(\d+)(?:\+(\d+))?' $a)[groups]

        monitor[width] = (num $mode[1][text])
        monitor[height] = (num $mode[2][text])
        monitor[x] = (num $mode[3][text])
        monitor[y] = (
          if (has-key $mode 3) {
            num 0
          } else {
            num $mode[3]
          }
        )
      }

      put $monitor
    }
  }
}

fn monitor-of-window [window]{
  for monitor [(monitors)] {
    if $monitor[connected] {
      after-start = (and (<= $monitor[x] $window[x]) (<= $monitor[y] $window[y]))
      before-end = (and (> (+ $monitor[x] $monitor[width]) $window[x]) (> (+ $monitor[y] $monitor[height]) $window[y]))

      if (and $after-start $before-end) {
        put $monitor
        return
      }
    }
  }

  fail 'unable to determine monitor of window'
}
