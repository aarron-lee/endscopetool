#!/usr/bin/bash

VENV_DIR="venv"

if [ -d "$VENV_DIR" ]; then
    echo "Virtual environment found. Activating..."
    source "$VENV_DIR/bin/activate"
else
    echo "Error: $VENV_DIR directory not found."
    python -m venv ./$VENV_DIR

    echo "Activating venv..."
    source "$VENV_DIR/bin/activate"

    echo "Install dependencies via pip"
    pip install -r requirements.txt
fi

./endscopetool.py
