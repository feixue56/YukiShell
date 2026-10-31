# Cloudflare WARP only when you want it: the warp-svc service no longer starts with the PC (Tailscale stays always on).
#   warp on       start the service and connect   (asks for your password)
#   warp off      disconnect and stop the service (asks for your password)
#   warp          status
function warp --description 'Cloudflare WARP on demand: warp on | off | status'
    switch "$argv[1]"
        case on
            systemctl start warp-svc; or return 1
            for i in (seq 50)
                warp-cli --accept-tos status >/dev/null 2>&1; and break
                sleep 0.2
            end
            warp-cli --accept-tos connect
        case off
            systemctl is-active -q warp-svc; and warp-cli --accept-tos disconnect >/dev/null 2>&1
            systemctl stop warp-svc
        case '' status
            if systemctl is-active -q warp-svc
                warp-cli --accept-tos status
            else
                echo "WARP is off (its service isn't running). Turn it on with: warp on"
            end
        case '*'
            echo "usage: warp [on | off | status]"
            return 1
    end
end
