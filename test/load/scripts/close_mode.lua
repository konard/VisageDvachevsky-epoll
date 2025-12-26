-- close_mode.lua - wrk script for testing Connection: close mode
-- This simulates the bug scenario: many short-lived connections
-- that send "Connection: close" header
--
-- Usage:
--   wrk -t4 -c100 -d10s -s scripts/close_mode.lua http://localhost:8080/
--
-- The key difference from default wrk behavior is that we explicitly
-- set "Connection: close" to force the server to close connections
-- after each request, testing the accept loop resilience.

wrk.method = "POST"
wrk.headers["Connection"] = "close"
wrk.headers["Content-Type"] = "application/json"
wrk.body = "[1.0, 2.0, 3.0]"

-- Counter for requests
local counter = 0

function request()
    counter = counter + 1
    return wrk.format("POST", "/compute/sum", wrk.headers, wrk.body)
end

function response(status, headers, body)
    -- Track non-2xx responses for debugging
    if status ~= 200 then
        io.write(string.format("status: %d\n", status))
    end
end

function done(summary, latency, requests)
    io.write("------------------------------\n")
    io.write("Connection: close mode test results\n")
    io.write("------------------------------\n")
    io.write(string.format("Requests:     %d\n", summary.requests))
    io.write(string.format("Errors:       connect=%d, read=%d, write=%d, status=%d, timeout=%d\n",
        summary.errors.connect,
        summary.errors.read,
        summary.errors.write,
        summary.errors.status,
        summary.errors.timeout))
    io.write(string.format("Duration:     %.2f seconds\n", summary.duration / 1000000))
    io.write(string.format("Throughput:   %.2f req/sec\n", summary.requests / (summary.duration / 1000000)))
    io.write(string.format("Latency avg:  %.2f ms\n", latency.mean / 1000))
    io.write(string.format("Latency max:  %.2f ms\n", latency.max / 1000))

    -- Check for ECONNREFUSED - the main symptom of the bug
    if summary.errors.connect > 0 then
        io.write("\nWARNING: Connection errors detected!\n")
        io.write("This may indicate the accept loop bug has regressed.\n")
        io.write("Check if KATANA_CONN_DEBUG=1 shows accept errors.\n")
    else
        io.write("\nSUCCESS: No connection errors!\n")
    end
end
