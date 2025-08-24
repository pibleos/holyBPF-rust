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



## Learning Path

Follow our recommended learning progression:

<div class="learning-path">
  <div class="path-step">
    <div class="step-number">1</div>
    <div class="step-content">
      <h4>Start Here</h4>
      <p><a href="{{ '/docs/examples/tutorials/hello-world' | relative_url }}">Hello World</a> - Learn the basics</p>
      <span class="difficulty">Beginner • 15 min</span>
    </div>
  </div>
  <div class="path-step">
    <div class="step-number">2</div>
    <div class="step-content">
      <h4>Build Contracts</h4>
      <p><a href="{{ '/docs/examples/tutorials/escrow' | relative_url }}">Escrow</a> - Multi-party agreements</p>
      <span class="difficulty">Beginner • 25 min</span>
    </div>
  </div>
  <div class="path-step">
    <div class="step-number">3</div>
    <div class="step-content">
      <h4>Token Systems</h4>
      <p><a href="{{ '/docs/examples/tutorials/solana-token' | relative_url }}">Token Program</a> - SPL integration</p>
      <span class="difficulty">Intermediate • 35 min</span>
    </div>
  </div>
  <div class="path-step">
    <div class="step-number">4</div>
    <div class="step-content">
      <h4>DeFi Protocols</h4>
      <p><a href="{{ '/docs/examples/tutorials/amm' | relative_url }}">AMM</a> - Automated market making</p>
      <span class="difficulty">Advanced • 45 min</span>
    </div>
  </div>
  <div class="path-step">
    <div class="step-number">5</div>
    <div class="step-content">
      <h4>Governance</h4>
      <p><a href="{{ '/docs/examples/tutorials/dao-governance' | relative_url }}">DAO</a> - Decentralized organizations</p>
      <span class="difficulty">Advanced • 50 min</span>
    </div>
  </div>
  <div class="path-step">
    <div class="step-number">6</div>
    <div class="step-content">
      <h4>Advanced DeFi</h4>
      <p><a href="{{ '/docs/examples/tutorials/yield-farming' | relative_url }}">Yield Farming</a> - Liquidity mining</p>
      <span class="difficulty">Expert • 60 min</span>
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

## Tutorial Search

<div class="tutorial-search">
  <input type="text" id="tutorial-search" placeholder="Search tutorials..." aria-label="Search tutorials">
  <div id="search-results" class="search-results"></div>
</div>

## Feedback

<div class="feedback-section">
  <h3>Help us improve! 📝</h3>
  <p>Found these tutorials helpful? Have suggestions for improvement?</p>
  <div class="feedback-buttons">
    <button class="feedback-btn positive" onclick="submitFeedback('positive')">👍 Helpful</button>
    <button class="feedback-btn negative" onclick="submitFeedback('negative')">👎 Needs improvement</button>
    <a href="https://github.com/pibleos/holyBPF-rust/issues/new?template=tutorial-feedback.md" class="feedback-btn github" target="_blank">💬 Detailed feedback</a>
  </div>
  <div id="feedback-message" class="feedback-message"></div>
</div>

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

.learning-path {
  margin: 2rem 0;
  display: flex;
  flex-direction: column;
  gap: 1rem;
}

.path-step {
  display: flex;
  align-items: flex-start;
  padding: 1rem;
  background: white;
  border: 2px solid #e1e5e9;
  border-radius: 8px;
  transition: all 0.3s ease;
}

.path-step:hover {
  border-color: #007bff;
  box-shadow: 0 2px 8px rgba(0, 123, 255, 0.1);
}

.step-number {
  background: #007bff;
  color: white;
  width: 32px;
  height: 32px;
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  font-weight: bold;
  font-size: 0.9rem;
  margin-right: 1rem;
  flex-shrink: 0;
}

.step-content h4 {
  margin: 0 0 0.5rem 0;
  color: #2c3e50;
  font-size: 1rem;
}

.step-content p {
  margin: 0 0 0.5rem 0;
  font-size: 0.9rem;
}

.step-content a {
  color: #007bff;
  text-decoration: none;
  font-weight: 500;
}

.step-content a:hover {
  text-decoration: underline;
}

.difficulty {
  font-size: 0.75rem;
  color: #666;
  background: #f8f9fa;
  padding: 0.25rem 0.5rem;
  border-radius: 12px;
  font-weight: 500;
}

@media (max-width: 768px) {
  .path-step {
    flex-direction: column;
    text-align: center;
  }
  
  .step-number {
    margin: 0 auto 1rem auto;
  }
}

/* Tutorial Search */
.tutorial-search {
  margin: 2rem 0;
  position: relative;
}

#tutorial-search {
  width: 100%;
  padding: 1rem;
  font-size: 1rem;
  border: 2px solid #e1e5e9;
  border-radius: 8px;
  background: white;
  transition: border-color 0.2s;
}

#tutorial-search:focus {
  outline: none;
  border-color: #007bff;
  box-shadow: 0 0 0 3px rgba(0, 123, 255, 0.1);
}

.search-results {
  position: absolute;
  top: 100%;
  left: 0;
  right: 0;
  background: white;
  border: 1px solid #e1e5e9;
  border-radius: 0 0 8px 8px;
  border-top: none;
  max-height: 200px;
  overflow-y: auto;
  z-index: 10;
  display: none;
}

.search-result {
  padding: 0.75rem 1rem;
  border-bottom: 1px solid #f8f9fa;
  cursor: pointer;
  transition: background-color 0.2s;
}

.search-result:hover {
  background: #f8f9fa;
}

.search-result:last-child {
  border-bottom: none;
}

.result-title {
  font-weight: 600;
  color: #2c3e50;
  margin-bottom: 0.25rem;
}

.result-description {
  font-size: 0.875rem;
  color: #6c757d;
}

/* Feedback Section */
.feedback-section {
  margin: 3rem 0 2rem 0;
  padding: 2rem;
  background: linear-gradient(135deg, #f8f9fa 0%, #e9ecef 100%);
  border-radius: 12px;
  border-left: 4px solid #28a745;
  text-align: center;
}

.feedback-section h3 {
  margin-bottom: 1rem;
  color: #2c3e50;
}

.feedback-buttons {
  display: flex;
  justify-content: center;
  gap: 1rem;
  margin: 1rem 0;
  flex-wrap: wrap;
}

.feedback-btn {
  padding: 0.75rem 1.5rem;
  border: none;
  border-radius: 6px;
  font-weight: 500;
  cursor: pointer;
  transition: all 0.2s;
  text-decoration: none;
  display: inline-block;
}

.feedback-btn.positive {
  background: #28a745;
  color: white;
}

.feedback-btn.negative {
  background: #dc3545;
  color: white;
}

.feedback-btn.github {
  background: #6f42c1;
  color: white;
}

.feedback-btn:hover {
  transform: translateY(-1px);
  box-shadow: 0 4px 8px rgba(0,0,0,0.15);
}

.feedback-btn:focus {
  outline: 2px solid #007bff;
  outline-offset: 2px;
}

.feedback-message {
  margin-top: 1rem;
  padding: 0.75rem;
  border-radius: 6px;
  font-weight: 500;
  display: none;
}

.feedback-message.success {
  background: #d4edda;
  color: #155724;
  border: 1px solid #c3e6cb;
}

.feedback-message.error {
  background: #f8d7da;
  color: #721c24;
  border: 1px solid #f5c6cb;
}
</style>

<script>
// Tutorial search functionality
document.addEventListener('DOMContentLoaded', function() {
    const tutorials = [
        {
            title: 'Hello World',
            description: 'Perfect introduction for beginners - Line-by-line code explanation',
            url: "{{ '/docs/examples/tutorials/hello-world' | relative_url }}",
            keywords: ['beginner', 'intro', 'basic', 'start', 'first', 'simple']
        },
        {
            title: 'Escrow Contract',
            description: 'Multi-party smart contract development - State machine design patterns',
            url: "{{ '/docs/examples/tutorials/escrow' | relative_url }}",
            keywords: ['contract', 'multi-party', 'state', 'agreement', 'secure']
        },
        {
            title: 'Token Program',
            description: 'Comprehensive token management - SPL Token standard integration',
            url: "{{ '/docs/examples/tutorials/solana-token' | relative_url }}",
            keywords: ['token', 'spl', 'solana', 'mint', 'transfer', 'authority']
        },
        {
            title: 'AMM Tutorial',
            description: 'Professional automated market maker - Constant product formula implementation',
            url: "{{ '/docs/examples/tutorials/amm' | relative_url }}",
            keywords: ['amm', 'defi', 'market', 'maker', 'liquidity', 'swap', 'formula']
        },
        {
            title: 'DAO Governance',
            description: 'Decentralized organization building - Proposal lifecycle management',
            url: "{{ '/docs/examples/tutorials/dao-governance' | relative_url }}",
            keywords: ['dao', 'governance', 'voting', 'proposal', 'democracy', 'organization']
        },
        {
            title: 'Yield Farming',
            description: 'Advanced liquidity mining - Dynamic APY calculation',
            url: "{{ '/docs/examples/tutorials/yield-farming' | relative_url }}",
            keywords: ['yield', 'farming', 'mining', 'apy', 'rewards', 'staking', 'boost']
        }
    ];

    const searchInput = document.getElementById('tutorial-search');
    const searchResults = document.getElementById('search-results');

    if (searchInput && searchResults) {
        searchInput.addEventListener('input', function() {
            const query = this.value.toLowerCase().trim();
            
            if (query.length < 2) {
                searchResults.style.display = 'none';
                return;
            }

            const filtered = tutorials.filter(tutorial => 
                tutorial.title.toLowerCase().includes(query) ||
                tutorial.description.toLowerCase().includes(query) ||
                tutorial.keywords.some(keyword => keyword.includes(query))
            );

            if (filtered.length > 0) {
                searchResults.innerHTML = filtered.map(tutorial => 
                    `<div class="search-result" onclick="window.location.href='${tutorial.url}'">
                        <div class="result-title">${tutorial.title}</div>
                        <div class="result-description">${tutorial.description}</div>
                    </div>`
                ).join('');
                searchResults.style.display = 'block';
            } else {
                searchResults.innerHTML = '<div class="search-result"><div class="result-title">No tutorials found</div><div class="result-description">Try different keywords</div></div>';
                searchResults.style.display = 'block';
            }
        });

        // Hide search results when clicking outside
        document.addEventListener('click', function(e) {
            if (!searchInput.contains(e.target) && !searchResults.contains(e.target)) {
                searchResults.style.display = 'none';
            }
        });
    }
});

// Feedback functionality
function submitFeedback(type) {
    const messageDiv = document.getElementById('feedback-message');
    
    if (type === 'positive') {
        messageDiv.textContent = '🙏 Thank you! Your feedback helps us improve these divine tutorials.';
        messageDiv.className = 'feedback-message success';
    } else if (type === 'negative') {
        messageDiv.textContent = '📝 Thank you for your feedback. Please use the detailed feedback link to tell us how we can improve.';
        messageDiv.className = 'feedback-message success';
    }
    
    messageDiv.style.display = 'block';
    
    // Auto-hide after 5 seconds
    setTimeout(() => {
        messageDiv.style.display = 'none';
    }, 5000);
    
    // Track feedback (in real implementation, this would send to analytics)
    if (typeof gtag !== 'undefined') {
        gtag('event', 'tutorial_feedback', {
            'feedback_type': type,
            'page_title': document.title
        });
    }
}
</script>