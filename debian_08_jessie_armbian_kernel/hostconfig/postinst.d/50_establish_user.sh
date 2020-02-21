#!/bin/sh -e

useradd -m linux-fan
( echo testwort; echo testwort ) | passwd linux-fan
