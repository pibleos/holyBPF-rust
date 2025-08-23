/**
 * HolyBPF Documentation - Main JavaScript
 * Handles navigation and interactive elements
 */

document.addEventListener('DOMContentLoaded', function() {
    // Mobile navigation toggle
    const navToggle = document.querySelector('.nav-toggle');
    const navMenu = document.querySelector('.nav-menu');
    
    if (navToggle && navMenu) {
        navToggle.addEventListener('click', function() {
            navMenu.classList.toggle('active');
            
            // Animate hamburger icon
            const spans = navToggle.querySelectorAll('span');
            spans.forEach((span, index) => {
                if (navMenu.classList.contains('active')) {
                    if (index === 0) span.style.transform = 'rotate(45deg) translate(5px, 5px)';
                    if (index === 1) span.style.opacity = '0';
                    if (index === 2) span.style.transform = 'rotate(-45deg) translate(7px, -6px)';
                } else {
                    span.style.transform = '';
                    span.style.opacity = '';
                }
            });
        });
    }
    
    // Close mobile menu when clicking outside
    document.addEventListener('click', function(e) {
        if (navMenu && navToggle && 
            !navMenu.contains(e.target) && 
            !navToggle.contains(e.target) && 
            navMenu.classList.contains('active')) {
            navMenu.classList.remove('active');
            
            // Reset hamburger icon
            const spans = navToggle.querySelectorAll('span');
            spans.forEach(span => {
                span.style.transform = '';
                span.style.opacity = '';
            });
        }
    });
    
    // Smooth scrolling for anchor links
    document.querySelectorAll('a[href^="#"]').forEach(anchor => {
        anchor.addEventListener('click', function(e) {
            e.preventDefault();
            const target = document.querySelector(this.getAttribute('href'));
            if (target) {
                target.scrollIntoView({
                    behavior: 'smooth',
                    block: 'start'
                });
            }
        });
    });
    
    // Add active state to current navigation item
    const currentPath = window.location.pathname;
    const navLinks = document.querySelectorAll('.nav-link');
    
    navLinks.forEach(link => {
        const linkPath = link.getAttribute('href');
        if (linkPath && currentPath.includes(linkPath) && linkPath !== '/') {
            link.classList.add('active');
        }
    });
    
    // Code block copy functionality
    const codeBlocks = document.querySelectorAll('pre code');
    
    codeBlocks.forEach(block => {
        const pre = block.parentElement;
        const button = document.createElement('button');
        button.className = 'copy-button';
        button.textContent = 'Copy';
        button.setAttribute('aria-label', 'Copy code to clipboard');
        
        button.addEventListener('click', async function() {
            try {
                await navigator.clipboard.writeText(block.textContent);
                button.textContent = 'Copied!';
                button.classList.add('copied');
                
                setTimeout(() => {
                    button.textContent = 'Copy';
                    button.classList.remove('copied');
                }, 2000);
            } catch (err) {
                console.error('Failed to copy text: ', err);
                button.textContent = 'Failed';
                
                setTimeout(() => {
                    button.textContent = 'Copy';
                }, 2000);
            }
        });
        
        pre.style.position = 'relative';
        pre.appendChild(button);
    });
    
    // Table of Contents generator for long pages
    const headings = document.querySelectorAll('h2, h3, h4');
    
    if (headings.length > 3) {
        const toc = document.createElement('nav');
        toc.className = 'table-of-contents';
        toc.innerHTML = '<h3>Table of Contents</h3>';
        
        const tocList = document.createElement('ul');
        
        headings.forEach((heading, index) => {
            // Add ID to heading if it doesn't have one
            if (!heading.id) {
                heading.id = `heading-${index}`;
            }
            
            const li = document.createElement('li');
            const a = document.createElement('a');
            a.href = `#${heading.id}`;
            a.textContent = heading.textContent;
            a.className = `toc-${heading.tagName.toLowerCase()}`;
            
            li.appendChild(a);
            tocList.appendChild(li);
        });
        
        toc.appendChild(tocList);
        
        // Insert TOC after the first paragraph
        const firstParagraph = document.querySelector('.page-content p');
        if (firstParagraph) {
            firstParagraph.parentNode.insertBefore(toc, firstParagraph.nextSibling);
        }
    }
    
    // Search functionality (basic)
    const searchInput = document.querySelector('#search-input');
    
    if (searchInput) {
        searchInput.addEventListener('input', function() {
            const query = this.value.toLowerCase();
            const searchableElements = document.querySelectorAll('.page-content h1, .page-content h2, .page-content h3, .page-content p');
            
            searchableElements.forEach(element => {
                const text = element.textContent.toLowerCase();
                if (query && text.includes(query)) {
                    element.style.background = '#ffff99';
                } else {
                    element.style.background = '';
                }
            });
        });
    }
    
    // Back to top button
    const backToTop = document.createElement('button');
    backToTop.className = 'back-to-top';
    backToTop.innerHTML = '↑';
    backToTop.setAttribute('aria-label', 'Back to top');
    document.body.appendChild(backToTop);
    
    backToTop.addEventListener('click', function() {
        window.scrollTo({
            top: 0,
            behavior: 'smooth'
        });
    });
    
    // Show/hide back to top button
    window.addEventListener('scroll', function() {
        if (window.pageYOffset > 300) {
            backToTop.classList.add('visible');
        } else {
            backToTop.classList.remove('visible');
        }
    });
});

// Add CSS for additional JavaScript features
const additionalStyles = `
.copy-button {
    position: absolute;
    top: 8px;
    right: 8px;
    background: var(--color-secondary);
    color: var(--color-white);
    border: none;
    padding: 4px 8px;
    font-size: 0.75rem;
    border-radius: 2px;
    cursor: pointer;
    opacity: 0;
    transition: opacity 0.2s;
}

pre:hover .copy-button {
    opacity: 1;
}

.copy-button:hover {
    background: var(--color-primary);
}

.copy-button.copied {
    background: #28a745;
}

.table-of-contents {
    background: var(--color-lightest);
    border: 1px solid var(--color-light);
    border-radius: var(--border-radius);
    padding: var(--spacing-lg);
    margin: var(--spacing-xl) 0;
}

.table-of-contents h3 {
    margin-bottom: var(--spacing-md);
    font-size: 1rem;
}

.table-of-contents ul {
    list-style: none;
    margin: 0;
    padding: 0;
}

.table-of-contents li {
    margin-bottom: var(--spacing-sm);
}

.table-of-contents a {
    text-decoration: none;
    color: var(--color-secondary);
    font-size: 0.875rem;
}

.table-of-contents a:hover {
    color: var(--color-primary);
    text-decoration: underline;
}

.toc-h3 {
    padding-left: var(--spacing-md);
}

.toc-h4 {
    padding-left: var(--spacing-xl);
}

.back-to-top {
    position: fixed;
    bottom: 20px;
    right: 20px;
    width: 40px;
    height: 40px;
    background: var(--color-primary);
    color: var(--color-white);
    border: none;
    border-radius: 50%;
    font-size: 1.2rem;
    cursor: pointer;
    opacity: 0;
    visibility: hidden;
    transition: all 0.3s;
    z-index: 1000;
}

.back-to-top.visible {
    opacity: 1;
    visibility: visible;
}

.back-to-top:hover {
    background: var(--color-secondary);
    transform: translateY(-2px);
}

.nav-link.active {
    color: var(--color-primary);
    font-weight: 600;
}

.nav-link.active::after {
    width: 100%;
}
`;

// Inject additional styles
const styleSheet = document.createElement('style');
styleSheet.textContent = additionalStyles;
document.head.appendChild(styleSheet);