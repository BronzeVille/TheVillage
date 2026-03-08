extends Node

## Serial LLM request queue — autoloaded as "AIQueue".
## Sends one request at a time to Ollama so the model isn't overloaded.
## Processes requests FIFO; each villager's callback is called with the raw
## Ollama response Dictionary when their turn completes.

const OLLAMA_URL: String = "http://127.0.0.1:11434/api/chat"

## Ollama model tag. Verify with: ollama list
## Qwen3.5-4B (thinking-capable). Adjust tag if yours differs.
const MODEL: String = "qwen3.5:4b"

## Max tokens to generate per response (keeps decisions snappy).
const NUM_PREDICT: int = 768

var _queue: Array[Dictionary] = []
var _busy: bool = false
var _http: HTTPRequest

## How many requests are waiting.
var queue_depth: int = 0


func _ready() -> void:
	_http = HTTPRequest.new()
	add_child(_http)
	_http.request_completed.connect(_on_request_completed)
	# Generous timeout for slow CPU inference (10 minutes)
	_http.timeout = 600.0


## Enqueue a decision request for a villager.
## villager_id: any int to identify the requester
## messages: Array of {role, content} dicts (system + user)
## callback: Callable(response: Dictionary) -> void
func enqueue(villager_id: int, messages: Array, callback: Callable) -> void:
	_queue.append({
		"id":       villager_id,
		"messages": messages,
		"callback": callback,
	})
	queue_depth = _queue.size()
	if not _busy:
		_process_next()


func _process_next() -> void:
	if _queue.is_empty():
		_busy = false
		queue_depth = 0
		return
	_busy = true
	var job: Dictionary = _queue.pop_front()
	queue_depth = _queue.size()
	_send(job)


func _send(job: Dictionary) -> void:
	var payload := {
		"model":   MODEL,
		"messages": job["messages"],
		"stream":  false,
		"think":   true,
		"options": {
			"temperature": 0.85,
			"num_predict": NUM_PREDICT,
		},
	}
	var headers := PackedStringArray(["Content-Type: application/json"])
	var err := _http.request(
		OLLAMA_URL,
		headers,
		HTTPClient.METHOD_POST,
		JSON.stringify(payload)
	)
	if err != OK:
		# HTTPRequest couldn't even start — skip this job
		push_warning("AIQueue: HTTPRequest failed to start (error %d)" % err)
		job["callback"].call({})
		_process_next()
		return
	_http.set_meta("job", job)


func _on_request_completed(
		result: int,
		response_code: int,
		_headers: PackedStringArray,
		body: PackedByteArray) -> void:

	var job: Dictionary = _http.get_meta("job")
	var parsed: Dictionary = {}

	if result == HTTPRequest.RESULT_SUCCESS and response_code == 200:
		var json := JSON.new()
		if json.parse(body.get_string_from_utf8()) == OK:
			var data = json.get_data()
			if data is Dictionary:
				parsed = data
		else:
			push_warning("AIQueue: JSON parse failed")
	else:
		push_warning("AIQueue: HTTP error result=%d code=%d" % [result, response_code])

	job["callback"].call(parsed)
	_process_next()
