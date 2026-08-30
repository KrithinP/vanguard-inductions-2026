# 34 — Actions, and commanding Nav2

> **By the end:** you can drive the navigation stack from code, and handle it
> properly when it fails.

## Why actions exist

You've used **topics** — fire and forget, no reply. Some things need more than
that. "Drive to this pose" takes a minute, you want progress while it happens,
you might want to cancel, and at the end you need to know whether it worked.

That's an **action**. Three parts:

| | |
|---|---|
| **Goal** | what you want. Sent once. |
| **Feedback** | progress, streamed while it runs |
| **Result** | how it ended, once |

Nav2's is `nav2_msgs/action/NavigateToPose`:

```bash
ros2 interface show nav2_msgs/action/NavigateToPose
ros2 action list          # /navigate_to_pose should be there once Nav2 is up
```

Try it by hand first, before writing anything:

```bash
ros2 action send_goal /navigate_to_pose nav2_msgs/action/NavigateToPose \
  "{pose: {header: {frame_id: map}, pose: {position: {x: 1.0, y: 0.0}, orientation: {w: 1.0}}}}" --feedback
```

If that doesn't move the rover, your code won't either. Fix it here.

## The shape of a client

You need, in order:

1. An `ActionClient(self, NavigateToPose, '/navigate_to_pose')`.
2. **`wait_for_server()` with a timeout.** If Nav2 isn't up, say so and stop —
   don't hang forever with no output. This is the single most common way a
   beginner's node appears to "do nothing".
3. Build a `NavigateToPose.Goal()`. The pose needs a **`frame_id`** (`map`) and a
   **valid orientation quaternion** — all zeros is not a rotation and Nav2 will
   reject or misbehave. `w = 1.0` is "facing along +x".
4. `send_goal_async(goal, feedback_callback=...)`. This returns a **future**, not
   a goal handle.
5. When that future resolves, check `goal_handle.accepted`. **A rejected goal
   never produces a result** — if you wait for one anyway, you wait forever.
6. `goal_handle.get_result_async()` for another future. When *that* resolves,
   read `result.status` and compare against `GoalStatus`
   (`STATUS_SUCCEEDED`, `STATUS_ABORTED`, `STATUS_CANCELED`).

## Async, and why you cannot avoid it

The tempting version is:

```python
future = client.send_goal_async(goal)
rclpy.spin_until_future_complete(self, future)   # inside a node method
```

Do not do this inside a callback. `spin` while already spinning **deadlocks** —
the node stops processing the very messages the future is waiting on. It looks
like a hang with no error, and it is the classic ROS 2 beginner deadlock.

Chain callbacks instead:

```
send_goal_async(...)  ->  .add_done_callback(self.on_goal_response)
    on_goal_response  ->  check accepted, then get_result_async()
                          .add_done_callback(self.on_result)
    on_result         ->  read the status, decide what to do next
```

Each step hands control back to ROS. Nothing blocks. Your explorer's "pick the
next frontier" logic lives at the end of `on_result` — which is also why the
whole thing naturally becomes a loop.

## Failure modes, and why they differ

| Outcome | Meaning | Reasonable response |
|---|---|---|
| **Rejected** | Nav2 refused it — often a malformed pose or an inactive server | Fix the goal; retrying identically won't help |
| **Aborted** | It tried and gave up — unreachable, or stuck | Give up on **this** goal, pick another |
| **Canceled** | You cancelled it | Whatever you cancelled it for |
| **Succeeded** | It arrived | Carry on | **Treating aborted as succeeded is the bug that makes an explorer loop forever**
on a frontier it cannot reach. Keep a record of goals that failed and don't offer
them again.

## Feedback

Your callback receives progress — including `distance_remaining`. Useful for
logging, and for noticing a rover that has stopped making progress while Nav2
still thinks it's working.

Don't do heavy work in there. It fires often.

## Diagnosing

| Symptom | Look at |
|---|---|
| Nothing happens, no output | Did `wait_for_server` succeed? Is `ros2 action list` showing it? |
| Node hangs silently | A blocking `spin_until_future_complete` inside a callback |
| Goal instantly rejected | Missing `frame_id`, or an all-zero quaternion |
| Always aborts | Goal in unknown or occupied space — check against the map |
| Rover moves, code never notices | You never subscribed to the result future |

Next: [`35-exploration.md`](35-exploration.md).
