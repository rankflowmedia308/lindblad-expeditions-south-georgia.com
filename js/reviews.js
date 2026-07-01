const API_KEY = 'AIzaSyAY3hxy7uGTIyWneh_shR-0oCm8ZZaPwiQ';

async function fetchPlaceDetails(placeId) {
  const url = `https://places.googleapis.com/v1/places/${placeId}`;
  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), 5000);
  try {
    const res = await fetch(url, {
      headers: {
        'X-Goog-Api-Key': API_KEY,
        'X-Goog-FieldMask': 'rating,userRatingCount,reviews'
      },
      signal: controller.signal
    });
    clearTimeout(timer);
    if (!res.ok) return null;
    return res.json();
  } catch {
    clearTimeout(timer);
    return null;
  }
}

function filterReviews(reviews) {
  return (reviews || [])
    .filter(r => r.rating >= 3)
    .filter(r => {
      const lang = r.text?.languageCode || '';
      return lang === 'en' || lang === '';
    })
    .slice(0, 5);
}

function renderStars(rating) {
  const full = Math.round(rating);
  return '★'.repeat(full) + '☆'.repeat(5 - full);
}

function escapeHtml(str) {
  return (str || '').replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;').replace(/"/g,'&quot;');
}

function renderReviews(reviews) {
  return reviews.map(r => {
    const text = r.text?.text || '';
    const preview = escapeHtml(text.slice(0, 140));
    const full = escapeHtml(text);
    const name = escapeHtml(r.authorAttribution?.displayName || 'Traveler');
    const date = escapeHtml(r.relativePublishTimeDescription || '');
    return `
      <div class="review-item">
        <div class="review-meta">
          <span class="reviewer-name">${name}</span>
          <span class="review-stars">${renderStars(r.rating)}</span>
          <span class="review-date">${date}</span>
        </div>
        <details class="review-text-wrapper">
          <summary>${preview}${text.length > 140 ? '…' : ''}</summary>
          <p>${full}</p>
        </details>
      </div>`;
  }).join('');
}

document.addEventListener('DOMContentLoaded', async () => {
  const cards = document.querySelectorAll('.review-card[data-place-id]');
  for (const card of cards) {
    const placeId = card.dataset.placeId;
    if (!placeId || placeId === 'static') continue;
    try {
      const data = await fetchPlaceDetails(placeId);
      if (!data) continue;

      card.querySelectorAll('[data-rating]').forEach(el => {
        if (data.rating) el.textContent = data.rating.toFixed(1);
      });
      card.querySelectorAll('.stars').forEach(el => {
        if (data.rating) el.textContent = renderStars(data.rating);
      });
      const countEl = card.querySelector('[data-review-count]');
      if (countEl && data.userRatingCount) {
        countEl.textContent = `${data.userRatingCount} Google reviews`;
      }
      const listEl = card.querySelector('[data-reviews-list]');
      if (listEl && data.reviews) {
        const filtered = filterReviews(data.reviews);
        if (filtered.length > 0) listEl.innerHTML = renderReviews(filtered);
      }
    } catch {
      // silent fallback — static HTML stays
    }
  }
});
