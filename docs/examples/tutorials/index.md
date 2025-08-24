---
layout: default
title: Example Tutorials
description: Step-by-step tutorials for HolyBPF examples
---

# Example Tutorials

Comprehensive step-by-step tutorials for all HolyBPF examples. Each tutorial provides complete setup instructions, code explanations, and practical results.

## Quick Navigation

<div class="content-grid">
  <div class="feature-card">
    <h3>🎯 Basic Examples</h3>
    <p>Start here to learn the fundamentals of HolyC BPF programming.</p>
    <div class="tutorial-links">
      <a href="{{ '/docs/examples/tutorials/hello-world' | relative_url }}" class="tutorial-link">Hello World →</a>
      <a href="{{ '/docs/examples/tutorials/escrow' | relative_url }}" class="tutorial-link">Escrow Contract →</a>
      <a href="{{ '/docs/examples/tutorials/solana-token' | relative_url }}" class="tutorial-link">Token Program →</a>
    </div>
  </div>
</div>

<div class="content-grid">
  <div class="feature-card">
    <h3>💰 DeFi Examples</h3>
    <p>Advanced DeFi protocols and financial applications.</p>
    <div class="tutorial-links">
      <a href="{{ '/docs/examples/tutorials/amm' | relative_url }}" class="tutorial-link">AMM →</a>
      <a href="{{ '/docs/examples/tutorials/yield-farming' | relative_url }}" class="tutorial-link">Yield Farming →</a>
    </div>
  </div>
</div>

<div class="content-grid">
  <div class="feature-card">
    <h3>🏛️ Governance & DAO</h3>
    <p>Decentralized governance and organizational tools.</p>
    <div class="tutorial-links">
      <a href="{{ '/docs/examples/tutorials/dao-governance' | relative_url }}" class="tutorial-link">DAO Governance →</a>
      <a href="{{ '/docs/examples/tutorials/yield-farming' | relative_url }}" class="tutorial-link">Yield Farming →</a>
    </div>
  </div>
</div>



## Tutorial Format

Each tutorial follows a consistent structure:

- **Overview**: What the example demonstrates
- **Prerequisites**: Required knowledge and setup
- **Code Walkthrough**: Line-by-line explanation
- **Building & Testing**: Step-by-step compilation
- **Expected Results**: What to expect when running
- **Next Steps**: Related examples and extensions

## Getting Help

- 📚 [Language Reference]({{ '/language-reference/' | relative_url }})
- 🛠️ [Getting Started Guide]({{ '/getting-started/' | relative_url }})
- 💡 [Code Snippets]({{ '/examples/snippets/' | relative_url }})

<style>
.content-grid {
  display: grid;
  grid-template-columns: 1fr;
  gap: 2rem;
  margin: 2rem 0;
}

.feature-card {
  border: 1px solid #e1e5e9;
  border-radius: 8px;
  padding: 1.5rem;
  background: #f8f9fa;
}

.feature-card h3 {
  margin-top: 0;
  color: #2c3e50;
}

.tutorial-links {
  display: flex;
  flex-wrap: wrap;
  gap: 0.5rem;
  margin-top: 1rem;
}

.tutorial-link {
  display: inline-block;
  padding: 0.5rem 1rem;
  background: #007bff;
  color: white;
  text-decoration: none;
  border-radius: 4px;
  font-size: 0.9rem;
  transition: background-color 0.2s;
}

.tutorial-link:hover {
  background: #0056b3;
  color: white;
  text-decoration: none;
}
</style>