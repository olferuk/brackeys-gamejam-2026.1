#!/usr/bin/env python3
"""
YAML to Dialogic Converter

Converts YAML dialogue files to Dialogic 2 timeline format (.dtl).

Usage:
    python yaml_to_dialogic.py                      # Convert all
    python yaml_to_dialogic.py dialogue_id          # Convert specific
    python yaml_to_dialogic.py --validate           # Validate only
    python yaml_to_dialogic.py --dry-run            # Show what would be generated
"""

import argparse
import json
import os
import sys
from pathlib import Path
from typing import Any, Optional

try:
    import yaml
except ImportError:
    print("ERROR: PyYAML not installed. Run: pip install pyyaml")
    sys.exit(1)

# Paths relative to project root
PROJECT_ROOT = Path(__file__).parent.parent
SRC_DIR = PROJECT_ROOT / "dialogues_src"
OUT_DIR = PROJECT_ROOT / "dialogues_generated"
CHARACTERS_DIR = OUT_DIR / "characters"


class DialogueConverter:
    """Converts a single YAML dialogue to Dialogic format."""
    
    def __init__(self, yaml_data: dict, source_file: str):
        self.data = yaml_data
        self.source_file = source_file
        self.errors: list[str] = []
        self.warnings: list[str] = []
        
        # Extract core data
        self.dialogue_id = yaml_data.get("id", "")
        self.title = yaml_data.get("title", self.dialogue_id)
        self.characters = yaml_data.get("characters", {})
        self.start_node = yaml_data.get("start", "")
        self.nodes = yaml_data.get("nodes", {})
    
    def validate(self) -> bool:
        """Validate the YAML structure. Returns True if valid."""
        if not self.dialogue_id:
            self.errors.append("Missing required field: 'id'")
        
        if not self.start_node:
            self.errors.append("Missing required field: 'start'")
        elif self.start_node not in self.nodes:
            self.errors.append(f"Start node '{self.start_node}' not found in nodes")
        
        if not self.nodes:
            self.errors.append("Missing required field: 'nodes' (or empty)")
        
        # Validate node references
        for node_id, node_data in self.nodes.items():
            self._validate_node(node_id, node_data)
        
        return len(self.errors) == 0
    
    def _validate_node(self, node_id: str, node: dict) -> None:
        """Validate a single node."""
        if not isinstance(node, dict):
            self.errors.append(f"Node '{node_id}' must be a dictionary")
            return
        
        # Check 'next' references
        next_node = node.get("next")
        if next_node and next_node not in self.nodes:
            self.errors.append(f"Node '{node_id}': 'next' references unknown node '{next_node}'")
        
        # Check choice references
        if "choice" in node:
            for i, choice in enumerate(node["choice"]):
                choice_next = choice.get("next")
                if choice_next and choice_next not in self.nodes:
                    self.errors.append(f"Node '{node_id}' choice {i}: references unknown node '{choice_next}'")
        
        # Check if/then/else references
        if "if" in node:
            then_node = node.get("then")
            else_node = node.get("else")
            if then_node and then_node not in self.nodes:
                self.errors.append(f"Node '{node_id}': 'then' references unknown node '{then_node}'")
            if else_node and else_node not in self.nodes:
                self.errors.append(f"Node '{node_id}': 'else' references unknown node '{else_node}'")
        
        # Check jump reference
        if "jump" in node:
            if node["jump"] not in self.nodes:
                self.errors.append(f"Node '{node_id}': 'jump' references unknown node '{node['jump']}'")
    
    def convert(self) -> str:
        """Convert to Dialogic timeline format (.dtl)."""
        events = []
        
        # Process nodes in order starting from start_node
        visited = set()
        self._process_node_chain(self.start_node, events, visited)
        
        # Build Dialogic timeline JSON
        timeline = {
            "events": events,
            "_metadata": {
                "source": self.source_file,
                "id": self.dialogue_id,
                "title": self.title,
            }
        }
        
        return json.dumps(timeline, indent=2, ensure_ascii=False)
    
    def _process_node_chain(self, node_id: str, events: list, visited: set) -> None:
        """Process a node and follow its chain."""
        if node_id in visited or node_id not in self.nodes:
            return
        visited.add(node_id)
        
        node = self.nodes[node_id]
        
        # Add label for this node (for jumps)
        events.append({
            "event_name": "dialogic_label_event",
            "name": node_id,
        })
        
        # Process node content
        self._process_node_content(node, events)
        
        # Follow 'next' if present and not an end
        if not node.get("end") and "next" in node:
            self._process_node_chain(node["next"], events, visited)
    
    def _process_node_content(self, node: dict, events: list) -> None:
        """Process the content of a single node."""
        
        # Say event
        if "say" in node:
            say_data = node["say"]
            if isinstance(say_data, dict):
                speaker = say_data.get("speaker", "")
                text = say_data.get("text", "")
            else:
                speaker = ""
                text = str(say_data)
            
            # Resolve character name
            char_name = speaker
            if speaker in self.characters:
                char_name = self.characters[speaker].get("name", speaker)
            
            events.append({
                "event_name": "dialogic_text_event",
                "character": speaker,  # Character ID for Dialogic
                "text": text,
            })
        
        # Choice event
        if "choice" in node:
            for choice in node["choice"]:
                choice_text = choice.get("text", "")
                choice_next = choice.get("next", "")
                choice_condition = choice.get("if")
                
                choice_event = {
                    "event_name": "dialogic_choice_event",
                    "text": choice_text,
                }
                
                if choice_condition:
                    choice_event["condition"] = str(choice_condition)
                
                events.append(choice_event)
                
                # Add jump to the choice target
                if choice_next:
                    events.append({
                        "event_name": "dialogic_jump_event",
                        "target": choice_next,
                    })
                    events.append({
                        "event_name": "dialogic_end_branch_event",
                    })
        
        # Set variables
        if "set" in node:
            for var_path, value in node["set"].items():
                events.append({
                    "event_name": "dialogic_variable_event",
                    "variable": var_path,
                    "value": value,
                    "operation": "set",
                })
        
        # Conditional (if/then/else)
        if "if" in node:
            condition = node["if"]
            then_target = node.get("then", "")
            else_target = node.get("else", "")
            
            events.append({
                "event_name": "dialogic_condition_event",
                "condition": str(condition),
            })
            
            if then_target:
                events.append({
                    "event_name": "dialogic_jump_event",
                    "target": then_target,
                })
            
            if else_target:
                events.append({
                    "event_name": "dialogic_else_event",
                })
                events.append({
                    "event_name": "dialogic_jump_event",
                    "target": else_target,
                })
            
            events.append({
                "event_name": "dialogic_end_branch_event",
            })
        
        # Jump
        if "jump" in node:
            events.append({
                "event_name": "dialogic_jump_event",
                "target": node["jump"],
            })
        
        # Signal/Event
        if "signal" in node:
            sig = node["signal"]
            events.append({
                "event_name": "dialogic_signal_event",
                "signal_name": sig.get("name", sig) if isinstance(sig, dict) else str(sig),
                "arguments": sig.get("args", {}) if isinstance(sig, dict) else {},
            })
        
        # End
        if "end" in node:
            end_value = node["end"]
            events.append({
                "event_name": "dialogic_end_event",
                "outcome": str(end_value) if end_value != True else "",
            })
    
    def generate_characters(self) -> dict[str, str]:
        """Generate Dialogic character resources. Returns {id: json_content}."""
        result = {}
        for char_id, char_data in self.characters.items():
            char_resource = {
                "resource_type": "DialogicCharacter",
                "display_name": char_data.get("name", char_id),
                "nicknames": [],
                "color": "Color(1, 1, 1, 1)",
                "portraits": {},
            }
            
            if "portrait" in char_data:
                char_resource["portraits"]["default"] = {
                    "scene": "",
                    "image": char_data["portrait"],
                }
            
            result[char_id] = json.dumps(char_resource, indent=2)
        
        return result


def convert_all(validate_only: bool = False, dry_run: bool = False) -> int:
    """Convert all YAML files. Returns exit code."""
    if not SRC_DIR.exists():
        print(f"ERROR: Source directory not found: {SRC_DIR}")
        return 1
    
    yaml_files = list(SRC_DIR.glob("*.yaml")) + list(SRC_DIR.glob("*.yml"))
    
    if not yaml_files:
        print(f"No YAML files found in {SRC_DIR}")
        return 0
    
    print(f"Found {len(yaml_files)} dialogue file(s)")
    
    # Ensure output directory exists
    if not dry_run and not validate_only:
        OUT_DIR.mkdir(parents=True, exist_ok=True)
        CHARACTERS_DIR.mkdir(parents=True, exist_ok=True)
    
    total_errors = 0
    
    for yaml_file in yaml_files:
        print(f"\n--- {yaml_file.name} ---")
        
        try:
            with open(yaml_file, "r", encoding="utf-8") as f:
                data = yaml.safe_load(f)
        except yaml.YAMLError as e:
            print(f"  ERROR: Invalid YAML: {e}")
            total_errors += 1
            continue
        
        if not data:
            print(f"  WARNING: Empty file, skipping")
            continue
        
        converter = DialogueConverter(data, yaml_file.name)
        
        # Validate
        if not converter.validate():
            for err in converter.errors:
                print(f"  ERROR: {err}")
            total_errors += len(converter.errors)
            continue
        
        for warn in converter.warnings:
            print(f"  WARNING: {warn}")
        
        if validate_only:
            print(f"  ✓ Valid")
            continue
        
        # Convert
        dtl_content = converter.convert()
        out_file = OUT_DIR / f"{converter.dialogue_id}.dtl"
        
        if dry_run:
            print(f"  Would generate: {out_file}")
            print(f"  Events: {dtl_content[:200]}...")
        else:
            with open(out_file, "w", encoding="utf-8") as f:
                f.write(dtl_content)
            print(f"  ✓ Generated: {out_file.name}")
        
        # Generate characters
        characters = converter.generate_characters()
        for char_id, char_json in characters.items():
            char_file = CHARACTERS_DIR / f"{char_id}.dch"
            if dry_run:
                print(f"  Would generate character: {char_file.name}")
            else:
                with open(char_file, "w", encoding="utf-8") as f:
                    f.write(char_json)
                print(f"  ✓ Character: {char_file.name}")
    
    print(f"\n{'='*40}")
    if total_errors > 0:
        print(f"Completed with {total_errors} error(s)")
        return 1
    else:
        print("All dialogues converted successfully!")
        return 0


def main():
    parser = argparse.ArgumentParser(description="Convert YAML dialogues to Dialogic format")
    parser.add_argument("dialogue_id", nargs="?", help="Specific dialogue ID to convert")
    parser.add_argument("--validate", action="store_true", help="Validate only, don't generate")
    parser.add_argument("--dry-run", action="store_true", help="Show what would be generated")
    
    args = parser.parse_args()
    
    # TODO: Support single dialogue conversion
    exit_code = convert_all(validate_only=args.validate, dry_run=args.dry_run)
    sys.exit(exit_code)


if __name__ == "__main__":
    main()
