/**
 * Synthetic.new Provider Extension
 * 
 * Adds synthetic.new as a provider for accessing open-source models
 * via their OpenAI-compatible API.
 * 
 * Requires: SYNTHETIC_API_KEY environment variable
 * 
 * API docs: https://dev.synthetic.new/docs/api/overview
 * Models: https://dev.synthetic.new/docs/api/models
 */
import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";

export default function (pi: ExtensionAPI) {
  pi.registerProvider("synthetic", {
    baseUrl: "https://api.synthetic.new/openai/v1",
    apiKey: "SYNTHETIC_API_KEY",
    api: "openai-completions",
    authHeader: true,
    models: [
      // ══════════════════════════════════════════════════════════════════════
      // Always-On Models (included in subscription)
      // ══════════════════════════════════════════════════════════════════════
      
      // Qwen models
      {
        id: "hf:Qwen/Qwen3.5-397B-A17B",
        name: "Qwen 3.5 397B",
        reasoning: false,
        input: ["text"],
        cost: { input: 0, output: 0, cacheRead: 0, cacheWrite: 0 },
        contextWindow: 256000,
        maxTokens: 8192,
      },
      {
        id: "hf:Qwen/Qwen3-235B-A22B-Thinking-2507",
        name: "Qwen 3 235B Thinking",
        reasoning: true,
        input: ["text"],
        cost: { input: 0, output: 0, cacheRead: 0, cacheWrite: 0 },
        contextWindow: 256000,
        maxTokens: 8192,
        compat: { thinkingFormat: "qwen" },
      },
      {
        id: "hf:Qwen/Qwen3-Coder-480B-A35B-Instruct",
        name: "Qwen 3 Coder 480B",
        reasoning: false,
        input: ["text"],
        cost: { input: 0, output: 0, cacheRead: 0, cacheWrite: 0 },
        contextWindow: 256000,
        maxTokens: 8192,
      },
      
      // DeepSeek models
      {
        id: "hf:deepseek-ai/DeepSeek-R1-0528",
        name: "DeepSeek R1",
        reasoning: true,
        input: ["text"],
        cost: { input: 0, output: 0, cacheRead: 0, cacheWrite: 0 },
        contextWindow: 128000,
        maxTokens: 8192,
      },
      {
        id: "hf:deepseek-ai/DeepSeek-V3-0324",
        name: "DeepSeek V3 (0324)",
        reasoning: false,
        input: ["text"],
        cost: { input: 0, output: 0, cacheRead: 0, cacheWrite: 0 },
        contextWindow: 128000,
        maxTokens: 8192,
      },
      {
        id: "hf:deepseek-ai/DeepSeek-V3.2",
        name: "DeepSeek V3.2",
        reasoning: false,
        input: ["text"],
        cost: { input: 0, output: 0, cacheRead: 0, cacheWrite: 0 },
        contextWindow: 159000,
        maxTokens: 8192,
      },
      {
        id: "hf:deepseek-ai/DeepSeek-V3",
        name: "DeepSeek V3",
        reasoning: false,
        input: ["text"],
        cost: { input: 0, output: 0, cacheRead: 0, cacheWrite: 0 },
        contextWindow: 128000,
        maxTokens: 8192,
      },
      
      // Kimi models (Moonshot AI)
      {
        id: "hf:moonshotai/Kimi-K2.5",
        name: "Kimi K2.5",
        reasoning: false,
        input: ["text"],
        cost: { input: 0, output: 0, cacheRead: 0, cacheWrite: 0 },
        contextWindow: 256000,
        maxTokens: 8192,
      },
      {
        id: "hf:nvidia/Kimi-K2.5-NVFP4",
        name: "Kimi K2.5 (NVFP4)",
        reasoning: false,
        input: ["text"],
        cost: { input: 0, output: 0, cacheRead: 0, cacheWrite: 0 },
        contextWindow: 256000,
        maxTokens: 8192,
      },
      {
        id: "hf:moonshotai/Kimi-K2-Instruct-0905",
        name: "Kimi K2 Instruct",
        reasoning: false,
        input: ["text"],
        cost: { input: 0, output: 0, cacheRead: 0, cacheWrite: 0 },
        contextWindow: 256000,
        maxTokens: 8192,
      },
      {
        id: "hf:moonshotai/Kimi-K2-Thinking",
        name: "Kimi K2 Thinking",
        reasoning: true,
        input: ["text"],
        cost: { input: 0, output: 0, cacheRead: 0, cacheWrite: 0 },
        contextWindow: 256000,
        maxTokens: 8192,
      },
      
      // MiniMax models
      {
        id: "hf:MiniMaxAI/MiniMax-M2.5",
        name: "MiniMax M2.5",
        reasoning: false,
        input: ["text"],
        cost: { input: 0, output: 0, cacheRead: 0, cacheWrite: 0 },
        contextWindow: 187000,
        maxTokens: 8192,
      },
      {
        id: "hf:MiniMaxAI/MiniMax-M2.1",
        name: "MiniMax M2.1",
        reasoning: false,
        input: ["text"],
        cost: { input: 0, output: 0, cacheRead: 0, cacheWrite: 0 },
        contextWindow: 192000,
        maxTokens: 8192,
      },
      
      // Other models
      {
        id: "hf:zai-org/GLM-4.7",
        name: "GLM 4.7",
        reasoning: false,
        input: ["text"],
        cost: { input: 0, output: 0, cacheRead: 0, cacheWrite: 0 },
        contextWindow: 198000,
        maxTokens: 8192,
      },
      {
        id: "hf:openai/gpt-oss-120b",
        name: "GPT OSS 120B",
        reasoning: false,
        input: ["text"],
        cost: { input: 0, output: 0, cacheRead: 0, cacheWrite: 0 },
        contextWindow: 128000,
        maxTokens: 8192,
      },
      {
        id: "hf:meta-llama/Llama-3.3-70B-Instruct",
        name: "Llama 3.3 70B",
        reasoning: false,
        input: ["text"],
        cost: { input: 0, output: 0, cacheRead: 0, cacheWrite: 0 },
        contextWindow: 128000,
        maxTokens: 8192,
      },
    ],
  });
}
