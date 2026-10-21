#!/usr/bin/env python3
"""
Unit and Schema Validation Tests for SentinelAI Guest Sensor
Verifies compatibility with Swift TelemetryEvent Codable schema.
"""

import unittest
import json
import tempfile
import os
import sys
from datetime import datetime

# Import sensor class
from sentinel_guest_sensor import GuestSensor, SENSOR_SOURCE

class TestGuestSensor(unittest.TestCase):
    def setUp(self):
        self.temp_file = tempfile.NamedTemporaryFile(delete=False, suffix=".jsonl")
        self.temp_file.close()

    def tearDown(self):
        if os.path.exists(self.temp_file.name):
            os.unlink(self.temp_file.name)

    def test_event_schema_conformance(self):
        """Verifica che gli eventi emessi rispettino lo schema Codable atteso dall'app Swift macOS."""
        sensor = GuestSensor(output_file=self.temp_file.name)
        sensor.emit_event(
            event_type="PROCESS_SPAWN",
            pid=1234,
            ppid=1,
            process_name="test_proc",
            command_line="/bin/test_proc --arg",
            raw_payload="test payload",
            is_untrusted_data=True
        )
        sensor.stop()

        with open(self.temp_file.name, "r", encoding="utf-8") as f:
            lines = [line.strip() for line in f if line.strip()]

        self.assertGreaterEqual(len(lines), 1)
        record = json.loads(lines[0])

        # Obbligatori per TelemetryEvent.swift
        self.assertIn("id", record)
        self.assertIn("timestamp", record)
        self.assertEqual(record["source"], SENSOR_SOURCE)
        self.assertEqual(record["eventType"], "PROCESS_SPAWN")
        self.assertTrue(record["isUntrustedData"])

        # Campi opzionali corretti
        self.assertEqual(record["pid"], 1234)
        self.assertEqual(record["ppid"], 1)
        self.assertEqual(record["processName"], "test_proc")
        self.assertEqual(record["commandLine"], "/bin/test_proc --arg")
        self.assertEqual(record["rawPayload"], "test payload")

        # Verifica timestamp ISO8601
        dt = datetime.fromisoformat(record["timestamp"])
        self.assertIsNotNone(dt)

    def test_burst_simulation_events(self):
        """Verifica generazione corretta di 15 scritture per la regola RULE-IO-014."""
        sensor = GuestSensor(output_file=self.temp_file.name)
        sensor.run_simulation("burst")
        sensor.stop()

        with open(self.temp_file.name, "r", encoding="utf-8") as f:
            lines = [json.loads(line) for line in f if line.strip()]

        file_events = [ev for ev in lines if ev.get("eventType") == "FILE_IO" and ev.get("filePath", "").startswith("/tmp/")]
        self.assertEqual(len(file_events), 15)
        for ev in file_events:
            self.assertEqual(ev.get("fileOperation"), "CREATE")
            self.assertEqual(ev.get("byteCount"), 4096)

    def test_unexpected_child_process_simulation(self):
        """Verifica simulazione interprete figlio per RULE-PROC-005."""
        sensor = GuestSensor(output_file=self.temp_file.name)
        sensor.run_simulation("child_proc")
        sensor.stop()

        with open(self.temp_file.name, "r", encoding="utf-8") as f:
            lines = [json.loads(line) for line in f if line.strip()]

        proc_events = [ev for ev in lines if ev.get("eventType") == "PROCESS_SPAWN"]
        self.assertEqual(len(proc_events), 2)
        child = proc_events[1]
        self.assertEqual(child.get("processName"), "sh")
        self.assertEqual(child.get("ppid"), 3010)

    def test_network_isolation_violation_simulation(self):
        """Verifica simulazione violazione rete per RULE-NET-003."""
        sensor = GuestSensor(output_file=self.temp_file.name)
        sensor.run_simulation("network")
        sensor.stop()

        with open(self.temp_file.name, "r", encoding="utf-8") as f:
            lines = [json.loads(line) for line in f if line.strip()]

        net_events = [ev for ev in lines if ev.get("eventType") == "NETWORK_ATTEMPT"]
        self.assertEqual(len(net_events), 1)
        self.assertEqual(net_events[0].get("destinationAddress"), "185.220.101.5")
        self.assertEqual(net_events[0].get("destinationPort"), 443)

    def test_persistence_simulation(self):
        """Verifica simulazione scrittura cron per RULE-PERSIST-002."""
        sensor = GuestSensor(output_file=self.temp_file.name)
        sensor.run_simulation("persistence")
        sensor.stop()

        with open(self.temp_file.name, "r", encoding="utf-8") as f:
            lines = [json.loads(line) for line in f if line.strip()]

        persist_events = [ev for ev in lines if ev.get("eventType") == "PERSISTENCE_WRITE"]
        self.assertEqual(len(persist_events), 1)
        self.assertIn("/etc/cron.d/", persist_events[0].get("filePath", ""))

    def test_hostile_prompt_injection_sanitization(self):
        """Verifica che stringhe ostili abbiano sempre isUntrustedData: True e non causino eccezioni."""
        sensor = GuestSensor(output_file=self.temp_file.name)
        sensor.run_simulation("tamper")
        sensor.stop()

        with open(self.temp_file.name, "r", encoding="utf-8") as f:
            lines = [json.loads(line) for line in f if line.strip()]

        tamper_events = [ev for ev in lines if ev.get("eventType") == "LOG_MESSAGE"]
        self.assertEqual(len(tamper_events), 1)
        self.assertTrue(tamper_events[0]["isUntrustedData"])
        self.assertIn("DISREGARD ALL PREVIOUS INSTRUCTIONS", tamper_events[0]["rawPayload"])

if __name__ == "__main__":
    unittest.main()
