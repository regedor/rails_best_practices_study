Delayed::Worker.destroy_failed_jobs = false
Delayed::Worker.sleep_delay = 10
Delayed::Worker.max_attempts = 2
Delayed::Worker.max_run_time = 30.minutes

Delayed::Worker.backend = :active_record
#OR
#silence_warnings do
#  Delayed::Worker.const_set("MAX_ATTEMPTS", 3)
#  Delayed::Worker.const_set("MAX_RUN_TIME", 5.minutes)
#end
