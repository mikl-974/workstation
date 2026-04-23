{ pkgs, ... }:
{
  # AI local desktop applications — for personal, local use on a workstation.
  #
  # Scope: local inference, desktop tooling, personal experimentation.
  # These tools are launched from the user's machine — they are NOT shared
  # services exposed to other machines on the network.
  #
  # For shared AI services (multi-machine access, GPU server), see ai-server
  # in the same infra repository. The separation is intentional and non-negotiable.
  environment.systemPackages = with pkgs; [
    # Local LLM inference runtime — run language models fully offline
    # Usage: `ollama pull llama3` then `ollama run llama3`
    # The API listens on localhost:11434 — not exposed to the network by default
    ollama

    # llama.cpp CLI tools — direct GGUF model inference, no daemon required
    # Useful for one-off inference, benchmarking, or scripting without ollama
    llama-cpp
  ];
}
