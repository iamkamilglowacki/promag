// Global variables
let surowce = [];
let produkty = [];
let dostawy = [];
let produkcje = [];

// Initialize the application
document.addEventListener('DOMContentLoaded', function() {
    initializeApp();
    updateCurrentTime();
    setInterval(updateCurrentTime, 1000);
});

function initializeApp() {
    setupNavigation();
    loadAllData();
}

// Cykle Produkcyjne functions
let cykle = [];
let cyklPozycjeCounter = 0;

async function loadCykle() {
    try {
        cykle = await apiCall('cykle');
        renderCykleContainer();
    } catch (error) {
        console.error('Error loading cykle:', error);
    }
}

function renderCykleContainer() {
    const container = document.getElementById('cykleContainer');
    
    if (cykle.length === 0) {
        container.innerHTML = '<div class="alert alert-info">Brak cykli produkcyjnych. Utwórz pierwszy cykl klikając przycisk "Nowy Cykl".</div>';
        return;
    }
    
    let html = '';
    cykle.forEach(cykl => {
        const statusBadge = cykl.status === 'wykonany' 
            ? '<span class="badge bg-success">Wykonany</span>' 
            : '<span class="badge bg-warning text-dark">Planowany</span>';
        
        html += `
            <div class="card mb-3">
                <div class="card-header">
                    <div class="d-flex justify-content-between align-items-center">
                        <h5 class="mb-0">${cykl.nazwa} ${statusBadge}</h5>
                        <div>
                            ${cykl.status === 'planowany' ? `
                                <button class="btn btn-sm btn-info me-2" onclick="sprawdzCykl(${cykl.id})">
                                    <i class="bi bi-check-circle"></i> Sprawdź zasoby
                                </button>
                                <button class="btn btn-sm btn-success me-2" onclick="wykonajCykl(${cykl.id})">
                                    <i class="bi bi-play-fill"></i> Wykonaj
                                </button>
                                <button class="btn btn-sm btn-danger" onclick="deleteCykl(${cykl.id})">
                                    <i class="bi bi-trash"></i>
                                </button>
                            ` : `
                                <small class="text-muted">Wykonano: ${cykl.data_wykonania}</small>
                            `}
                        </div>
                    </div>
                </div>
                <div class="card-body">
                    <h6>Produkty w cyklu:</h6>
                    <ul class="list-group">
                        ${cykl.pozycje.map(p => `
                            <li class="list-group-item d-flex justify-content-between align-items-center">
                                ${p.produkt_nazwa}
                                <span class="badge bg-primary">${p.ilosc} szt. (${p.produkt_gramatura}g/szt.)</span>
                            </li>
                        `).join('')}
                    </ul>
                </div>
            </div>
        `;
    });
    
    container.innerHTML = html;
}

function addCyklPozycja() {
    cyklPozycjeCounter++;
    const container = document.getElementById('cyklPozycje');
    
    const pozycjaHtml = `
        <div class="row mb-2" id="pozycja-${cyklPozycjeCounter}">
            <div class="col-md-7">
                <select class="form-select" id="produkt-${cyklPozycjeCounter}" required>
                    <option value="">-- Wybierz produkt --</option>
                    ${produkty.map(p => `<option value="${p.id}">${p.nazwa} (${p.gramatura_sloika}g/szt.)</option>`).join('')}
                </select>
            </div>
            <div class="col-md-3">
                <input type="number" class="form-control" id="ilosc-${cyklPozycjeCounter}" placeholder="Ilość (szt.)" min="1" required>
            </div>
            <div class="col-md-2">
                <button type="button" class="btn btn-danger" onclick="removeCyklPozycja(${cyklPozycjeCounter})">
                    <i class="bi bi-trash"></i>
                </button>
            </div>
        </div>
    `;
    
    container.insertAdjacentHTML('beforeend', pozycjaHtml);
}

function removeCyklPozycja(id) {
    document.getElementById(`pozycja-${id}`).remove();
}

async function saveCykl() {
    const nazwa = document.getElementById('cyklNazwa').value;
    
    if (!nazwa.trim()) {
        showToast('Błąd', 'Nazwa cyklu jest wymagana', 'error');
        return;
    }
    
    // Zbierz pozycje
    const pozycje = [];
    const container = document.getElementById('cyklPozycje');
    const rows = container.querySelectorAll('[id^="pozycja-"]');
    
    for (const row of rows) {
        const id = row.id.split('-')[1];
        const produktId = document.getElementById(`produkt-${id}`).value;
        const ilosc = parseInt(document.getElementById(`ilosc-${id}`).value);
        
        if (!produktId || !ilosc || ilosc <= 0) {
            showToast('Błąd', 'Wszystkie pozycje muszą mieć wybrany produkt i ilość', 'error');
            return;
        }
        
        pozycje.push({
            produkt_id: parseInt(produktId),
            ilosc: ilosc
        });
    }
    
    if (pozycje.length === 0) {
        showToast('Błąd', 'Dodaj przynajmniej jeden produkt do cyklu', 'error');
        return;
    }
    
    // Sprawdź dostępność zasobów przed utworzeniem cyklu
    const zapotrzebowanie = {};
    
    for (const pozycja of pozycje) {
        const produkt = produkty.find(p => p.id === pozycja.produkt_id);
        const receptury = await apiCall(`receptury/${pozycja.produkt_id}`);
        
        const iloscGramProdukt = pozycja.ilosc * produkt.gramatura_sloika;
        
        for (const receptura of receptury) {
            const potrzebnaIlosc = (receptura.ilosc_na_100g / 100) * iloscGramProdukt;
            
            if (zapotrzebowanie[receptura.surowiec_id]) {
                zapotrzebowanie[receptura.surowiec_id] += potrzebnaIlosc;
            } else {
                zapotrzebowanie[receptura.surowiec_id] = potrzebnaIlosc;
            }
        }
    }
    
    // Sprawdź czy są dostępne zasoby
    const braki = [];
    for (const [surowiecId, potrzebna] of Object.entries(zapotrzebowanie)) {
        const surowiec = surowce.find(s => s.id === parseInt(surowiecId));
        if (surowiec.stan_magazynowy < potrzebna) {
            braki.push({
                nazwa: surowiec.nazwa,
                potrzebna: potrzebna.toFixed(1),
                dostepna: surowiec.stan_magazynowy.toFixed(1),
                brakuje: (potrzebna - surowiec.stan_magazynowy).toFixed(1)
            });
        }
    }
    
    if (braki.length > 0) {
        let brakiHtml = '<div class="alert alert-danger"><strong>Brak wystarczających zasobów!</strong><ul class="mb-0 mt-2">';
        braki.forEach(b => {
            brakiHtml += `<li>${b.nazwa}: potrzeba ${b.potrzebna}g, dostępne ${b.dostepna}g, <strong>brakuje ${b.brakuje}g</strong></li>`;
        });
        brakiHtml += '</ul></div>';
        
        document.getElementById('cyklValidation').innerHTML = brakiHtml;
        document.getElementById('cyklValidation').style.display = 'block';
        
        showToast('Błąd', 'Nie można zaplanować cyklu - brak wystarczających surowców', 'error');
        return;
    }
    
    // Jeśli wszystko OK, utwórz cykl
    try {
        await apiCall('cykle', 'POST', {
            nazwa: nazwa,
            pozycje: pozycje
        });
        
        document.getElementById('newCyklForm').reset();
        document.getElementById('cyklPozycje').innerHTML = '';
        document.getElementById('cyklValidation').style.display = 'none';
        cyklPozycjeCounter = 0;
        
        bootstrap.Modal.getInstance(document.getElementById('newCyklModal')).hide();
        
        await loadCykle();
        showToast('Sukces', 'Cykl produkcyjny został zaplanowany', 'success');
    } catch (error) {
        console.error('Error creating cykl:', error);
    }
}

async function sprawdzCykl(id) {
    try {
        const wynik = await apiCall(`cykle/${id}/sprawdz`);
        
        let html = `
            <div class="modal fade" id="sprawdzCyklModal" tabindex="-1">
                <div class="modal-dialog modal-lg">
                    <div class="modal-content">
                        <div class="modal-header ${wynik.mozliwe ? 'bg-success' : 'bg-danger'} text-white">
                            <h5 class="modal-title">
                                <i class="bi bi-${wynik.mozliwe ? 'check-circle' : 'x-circle'}"></i>
                                ${wynik.mozliwe ? 'Cykl możliwy do wykonania' : 'Brak wystarczających zasobów'}
                            </h5>
                            <button type="button" class="btn-close btn-close-white" data-bs-dismiss="modal"></button>
                        </div>
                        <div class="modal-body">
                            <h6>Zapotrzebowanie na surowce:</h6>
                            <table class="table table-sm">
                                <thead>
                                    <tr>
                                        <th>Surowiec</th>
                                        <th>Potrzebna</th>
                                        <th>Dostępna</th>
                                        <th>Status</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    ${wynik.surowce.map(s => `
                                        <tr class="${s.wystarczy ? '' : 'table-danger'}">
                                            <td>${s.surowiec_nazwa}</td>
                                            <td>${s.potrzebna}g</td>
                                            <td>${s.dostepna}g</td>
                                            <td>
                                                ${s.wystarczy 
                                                    ? '<span class="badge bg-success">OK</span>' 
                                                    : `<span class="badge bg-danger">Brakuje ${s.brakuje}g</span>`
                                                }
                                            </td>
                                        </tr>
                                    `).join('')}
                                </tbody>
                            </table>
                        </div>
                        <div class="modal-footer">
                            <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Zamknij</button>
                        </div>
                    </div>
                </div>
            </div>
        `;
        
        // Usuń stary modal jeśli istnieje
        const oldModal = document.getElementById('sprawdzCyklModal');
        if (oldModal) oldModal.remove();
        
        // Dodaj nowy modal
        document.body.insertAdjacentHTML('beforeend', html);
        
        // Pokaż modal
        const modal = new bootstrap.Modal(document.getElementById('sprawdzCyklModal'));
        modal.show();
        
        // Usuń modal po zamknięciu
        document.getElementById('sprawdzCyklModal').addEventListener('hidden.bs.modal', function() {
            this.remove();
        });
        
    } catch (error) {
        console.error('Error checking cykl:', error);
    }
}

async function wykonajCykl(id) {
    if (!confirm('Czy na pewno chcesz wykonać ten cykl produkcyjny? Spowoduje to odejmowanie surowców i dodanie produktów do magazynu.')) {
        return;
    }
    
    try {
        await apiCall(`cykle/${id}/wykonaj`, 'POST');
        await loadCykle();
        await loadAllData();
        showToast('Sukces', 'Cykl produkcyjny został wykonany', 'success');
    } catch (error) {
        console.error('Error executing cykl:', error);
    }
}

async function deleteCykl(id) {
    if (!confirm('Czy na pewno chcesz usunąć ten cykl?')) {
        return;
    }
    
    try {
        await apiCall(`cykle/${id}`, 'DELETE');
        await loadCykle();
        showToast('Sukces', 'Cykl został usunięty', 'success');
    } catch (error) {
        console.error('Error deleting cykl:', error);
    }
}

function setupNavigation() {
    const navItems = document.querySelectorAll('[data-tab]');
    navItems.forEach(item => {
        item.addEventListener('click', function(e) {
            e.preventDefault();
            const tabName = this.getAttribute('data-tab');
            switchTab(tabName);
        });
    });
}

function switchTab(tabName) {
    // Hide all tabs
    document.querySelectorAll('.tab-content').forEach(tab => {
        tab.classList.remove('active');
    });
    
    // Show selected tab
    document.getElementById(tabName).classList.add('active');
    
    // Update navigation
    document.querySelectorAll('[data-tab]').forEach(item => {
        item.classList.remove('active');
    });
    document.querySelector(`[data-tab="${tabName}"]`).classList.add('active');
    
    // Load tab-specific data
    switch(tabName) {
        case 'dashboard':
            updateDashboard();
            break;
        case 'surowce':
            loadSurowce();
            break;
        case 'produkty':
            loadProdukty();
            break;
        case 'receptury':
            loadReceptury();
            break;
        case 'dostawy':
            loadDostawy();
            break;
        case 'produkcja':
            loadProdukcja();
            break;
        case 'cykle':
            loadCykle();
            break;
    }
}

function updateCurrentTime() {
    const now = new Date();
    const timeString = now.toLocaleString('pl-PL');
    document.getElementById('currentTime').textContent = timeString;
}

// API calls
async function apiCall(endpoint, method = 'GET', data = null) {
    try {
        const options = {
            method: method,
            headers: {
                'Content-Type': 'application/json',
            }
        };
        
        if (data) {
            options.body = JSON.stringify(data);
        }
        
        const response = await fetch(`/api/${endpoint}`, options);
        
        if (!response.ok) {
            // Sprawdź czy odpowiedź to JSON czy HTML
            const contentType = response.headers.get('content-type');
            let errorMessage = `Błąd ${response.status}: ${response.statusText}`;
            
            if (contentType && contentType.includes('application/json')) {
                try {
                    const errorData = await response.json();
                    errorMessage = errorData.error || errorMessage;
                } catch (e) {
                    // Jeśli parsowanie JSON się nie powiedzie, użyj domyślnej wiadomości
                    console.error('Failed to parse error JSON:', e);
                }
            } else {
                // Dla HTML lub innych typów, spróbuj pobrać tekst
                try {
                    const errorText = await response.text();
                    if (errorText.length < 200) {
                        errorMessage = errorText;
                    }
                } catch (e) {
                    console.error('Failed to read error text:', e);
                }
            }
            
            throw new Error(errorMessage);
        }
        
        return await response.json();
    } catch (error) {
        console.error('API Error:', error);
        showToast('Błąd', error.message, 'error');
        throw error;
    }
}

// Load all data
async function loadAllData() {
    try {
        surowce = await apiCall('surowce');
        produkty = await apiCall('produkty');
        dostawy = await apiCall('dostawy');
        produkcje = await apiCall('produkcja');
        potencjal = await apiCall('potencjal');
        
        updateDashboard();
        populateSelects();
    } catch (error) {
        console.error('Error loading data:', error);
    }
}

// Dashboard functions
function updateDashboard() {
    // Update statistics
    document.getElementById('totalSurowce').textContent = surowce.length;
    document.getElementById('totalProdukty').textContent = produkty.length;
    
    const totalWartosc = surowce.reduce((sum, s) => sum + s.wartosc_magazynowa, 0);
    document.getElementById('totalWartosc').textContent = totalWartosc.toFixed(2) + ' zł';
    
    const lowStock = surowce.filter(s => s.stan_magazynowy < 100).length;
    document.getElementById('lowStock').textContent = lowStock;
    
    // Update ostatnie działania
    updateOstatnieDzialania();
}

function updateOstatnieDzialania() {
    const container = document.getElementById('ostatnieDzialania');
    const allActions = [];
    
    // Add recent deliveries
    dostawy.slice(0, 3).forEach(d => {
        allActions.push({
            type: 'dostawa',
            date: d.data,
            description: `Dostawa: ${d.surowiec_nazwa} (${d.ilosc}g)`
        });
    });
    
    // Add recent production
    produkcje.slice(0, 3).forEach(p => {
        allActions.push({
            type: 'produkcja',
            date: p.data,
            description: `Produkcja: ${p.produkt_nazwa} (${p.ilosc}g)`
        });
    });
    
    // Sort by date
    allActions.sort((a, b) => new Date(b.date) - new Date(a.date));
    
    if (allActions.length === 0) {
        container.innerHTML = '<p class="text-muted">Brak ostatnich działań</p>';
        return;
    }
    
    let html = '';
    allActions.slice(0, 5).forEach(action => {
        const icon = action.type === 'dostawa' ? 'truck' : 'gear';
        const color = action.type === 'dostawa' ? 'text-success' : 'text-primary';
        html += `
            <div class="d-flex align-items-center mb-2">
                <i class="bi bi-${icon} ${color} me-2"></i>
                <div>
                    <div>${action.description}</div>
                    <small class="text-muted">${action.date}</small>
                </div>
            </div>
        `;
    });
    container.innerHTML = html;
}

// Surowce functions
async function loadSurowce() {
    try {
        surowce = await apiCall('surowce');
        // Sortuj alfabetycznie po nazwie
        surowce.sort((a, b) => a.nazwa.localeCompare(b.nazwa, 'pl'));
        renderSurowceTable();
    } catch (error) {
        console.error('Error loading surowce:', error);
    }
}

function renderSurowceTable() {
    const tbody = document.getElementById('surowceTable');
    
    if (surowce.length === 0) {
        tbody.innerHTML = '<tr><td colspan="5" class="text-center text-muted">Brak surowców</td></tr>';
        return;
    }
    
    let html = '';
    surowce.forEach(surowiec => {
        const stockClass = getStockClass(surowiec.stan_magazynowy);
        html += `
            <tr data-nazwa="${surowiec.nazwa.toLowerCase()}">
                <td>${surowiec.nazwa}</td>
                <td class="${stockClass}">${surowiec.stan_magazynowy.toFixed(1)}</td>
                <td>${surowiec.cena_jednostkowa.toFixed(3)}</td>
                <td>${surowiec.wartosc_magazynowa.toFixed(2)}</td>
                <td>
                    <button class="btn btn-sm btn-outline-primary" onclick="editSurowiec(${surowiec.id})">
                        <i class="bi bi-pencil"></i>
                    </button>
                    <button class="btn btn-sm btn-outline-warning" onclick="openKorektaSurowiec(${surowiec.id})" title="Korekta manualna">
                        <i class="bi bi-exclamation-triangle"></i>
                    </button>
                    <button class="btn btn-sm btn-outline-danger" onclick="deleteSurowiec(${surowiec.id}, '${surowiec.nazwa}')" title="Usuń surowiec">
                        <i class="bi bi-trash"></i>
                    </button>
                </td>
            </tr>
        `;
    });
    tbody.innerHTML = html;
    
    // Reinicjalizuj zaznaczanie po renderowaniu
    if (typeof initRowSelection === 'function') {
        initRowSelection('surowceTable');
    }
}

function filterSurowceTable() {
    const searchText = document.getElementById('surowceSearch').value.toLowerCase();
    const tbody = document.getElementById('surowceTable');
    const rows = tbody.getElementsByTagName('tr');
    
    let visibleCount = 0;
    
    for (let i = 0; i < rows.length; i++) {
        const row = rows[i];
        const nazwa = row.getAttribute('data-nazwa');
        
        if (!nazwa) continue; // Pomiń wiersz "Brak surowców"
        
        if (nazwa.includes(searchText)) {
            row.style.display = '';
            visibleCount++;
        } else {
            row.style.display = 'none';
        }
    }
    
    // Jeśli nic nie znaleziono, pokaż komunikat
    if (visibleCount === 0 && searchText !== '') {
        const existingMsg = tbody.querySelector('.no-results-row');
        if (!existingMsg) {
            const noResultsRow = document.createElement('tr');
            noResultsRow.className = 'no-results-row';
            noResultsRow.innerHTML = '<td colspan="5" class="text-center text-muted">Nie znaleziono surowców pasujących do wyszukiwania</td>';
            tbody.appendChild(noResultsRow);
        }
    } else {
        const existingMsg = tbody.querySelector('.no-results-row');
        if (existingMsg) {
            existingMsg.remove();
        }
    }
}

function getStockClass(stock) {
    if (stock < 50) return 'low-stock';
    if (stock < 200) return 'medium-stock';
    return 'good-stock';
}

async function addSurowiec() {
    const nazwa = document.getElementById('surowiecNazwa').value;
    const stan = parseFloat(document.getElementById('surowiecStan').value) || 0;
    const cena = parseFloat(document.getElementById('surowiecCena').value) || 0;
    
    if (!nazwa.trim()) {
        showToast('Błąd', 'Nazwa surowca jest wymagana', 'error');
        return;
    }
    
    try {
        await apiCall('surowce', 'POST', {
            nazwa: nazwa,
            stan_magazynowy: stan,
            cena_jednostkowa: cena
        });
        
        document.getElementById('addSurowiecForm').reset();
        bootstrap.Modal.getInstance(document.getElementById('addSurowiecModal')).hide();
        
        await loadSurowce();
        await loadAllData(); // Refresh all data
        showToast('Sukces', 'Surowiec został dodany', 'success');
    } catch (error) {
        console.error('Error adding surowiec:', error);
    }
}

// Produkty functions
async function loadProdukty() {
    try {
        produkty = await apiCall('produkty');
        renderProduktyTable();
    } catch (error) {
        console.error('Error loading produkty:', error);
    }
}

function renderProduktyTable() {
    const tbody = document.getElementById('produktyTable');
    
    if (produkty.length === 0) {
        tbody.innerHTML = '<tr><td colspan="7" class="text-center text-muted">Brak produktów</td></tr>';
        return;
    }
    
    let html = '';
    produkty.forEach(produkt => {
        const stockClass = getStockClass(produkt.stan_magazynowy);
        const maxProdClass = getStockClass(produkt.max_produkcja || 0);
        const maxProdText = produkt.max_produkcja !== undefined ? produkt.max_produkcja : '-';
        const tooltipText = produkt.ograniczajacy_surowiec ? `Ogranicza: ${produkt.ograniczajacy_surowiec}` : '';
        
        // Dodaj ikonę informacji jeśli są szczegóły surowców
        const infoIcon = produkt.surowce_details && produkt.surowce_details.length > 0 
            ? `<i class="bi bi-info-circle ms-1" style="cursor: pointer; color: #0d6efd;" onclick="showSurowceDetails(${produkt.id})" title="Szczegóły surowców"></i>` 
            : '';
        
        html += `
            <tr>
                <td>${produkt.nazwa}</td>
                <td>${produkt.opis || '-'}</td>
                <td class="${stockClass}">${produkt.stan_magazynowy}</td>
                <td>${produkt.gramatura_sloika}g</td>
                <td>${produkt.stan_w_gramach.toFixed(1)}g</td>
                <td class="${maxProdClass}" title="${tooltipText}">
                    ${maxProdText}${infoIcon}
                </td>
                <td>
                    <button class="btn btn-sm btn-outline-primary" onclick="editProdukt(${produkt.id})">
                        <i class="bi bi-pencil"></i>
                    </button>
                    <button class="btn btn-sm btn-outline-warning" onclick="openKorektaProdukt(${produkt.id})" title="Korekta manualna">
                        <i class="bi bi-exclamation-triangle"></i>
                    </button>
                    <button class="btn btn-sm btn-outline-danger" onclick="deleteProdukt(${produkt.id}, '${produkt.nazwa}')" title="Usuń produkt">
                        <i class="bi bi-trash"></i>
                    </button>
                </td>
            </tr>
        `;
    });
    tbody.innerHTML = html;
    
    // Reinicjalizuj zaznaczanie po renderowaniu
    if (typeof initRowSelection === 'function') {
        initRowSelection('produktyTable');
    }
}

// Receptury functions
async function loadReceptury() {
    try {
        produkty = await apiCall('produkty');
        await renderRecepturyContainer();
    } catch (error) {
        console.error('Error loading receptury:', error);
    }
}

async function renderRecepturyContainer() {
    const container = document.getElementById('recepturyContainer');
    
    if (produkty.length === 0) {
        container.innerHTML = '<div class="alert alert-info">Brak produktów. Dodaj pierwszy produkt w zakładce Produkty.</div>';
        return;
    }
    
    let html = '';
    for (const produkt of produkty) {
        const receptury = await apiCall(`receptury/${produkt.id}`);
        
        const kolorEtykiety = produkt.kolor_etykiety || '#6c757d';
        // Oblicz jasność koloru, aby wybrać odpowiedni kolor tekstu
        const rgb = parseInt(kolorEtykiety.slice(1), 16);
        const r = (rgb >> 16) & 0xff;
        const g = (rgb >>  8) & 0xff;
        const b = (rgb >>  0) & 0xff;
        const brightness = (r * 299 + g * 587 + b * 114) / 1000;
        const textColor = brightness > 128 ? '#000000' : '#ffffff';
        
        html += `
            <div class="card mb-3" style="background-color: ${kolorEtykiety}; color: ${textColor};">
                <div class="card-header" style="background-color: rgba(0,0,0,0.1); border: none; color: ${textColor};">
                    <div class="d-flex justify-content-between align-items-center">
                        <div class="d-flex align-items-center gap-2">
                            <h5 class="mb-0">${produkt.nazwa}</h5>
                        </div>
                        <div>
                            <button class="btn btn-sm btn-outline-light" onclick="openEditKolorModal(${produkt.id}, '${produkt.nazwa}', '${kolorEtykiety}')" title="Zmień kolor">
                                <i class="bi bi-palette"></i>
                            </button>
                            <button class="btn btn-sm btn-outline-light" onclick="showAddSkladnikModal(${produkt.id}, '${produkt.nazwa}')">
                                <i class="bi bi-plus"></i> Dodaj składnik
                            </button>
                            <button class="btn btn-sm btn-outline-danger" onclick="deleteProduktFromReceptura(${produkt.id}, '${produkt.nazwa}')" title="Usuń produkt">
                                <i class="bi bi-trash"></i>
                            </button>
                        </div>
                    </div>
                    ${produkt.opis ? `<small style="opacity: 0.9;">${produkt.opis}</small>` : ''}
                </div>
                <div class="card-body" style="background-color: rgba(255,255,255,0.9); color: #000;">
                    <h6>Receptura (na 100g produktu):</h6>
                    <div id="receptury-${produkt.id}">
                        ${renderReceptury(receptury)}
                    </div>
                </div>
            </div>
        `;
    }
    
    container.innerHTML = html;
}

function renderReceptury(receptury) {
    if (receptury.length === 0) {
        return '<p class="text-muted">Brak składników w recepturze</p>';
    }
    
    let html = '<div class="row g-2">';
    receptury.forEach(r => {
        html += `
            <div class="col-md-4 col-lg-3">
                <div class="receptura-item p-2 border rounded bg-light">
                    <div class="d-flex justify-content-between align-items-center">
                        <div class="text-truncate me-2" style="font-size: 0.9rem;">
                            <strong>${r.surowiec_nazwa}</strong>
                            <div class="text-muted" style="font-size: 0.85rem;">${r.ilosc_na_100g}g</div>
                        </div>
                        <button class="btn btn-sm btn-outline-danger" onclick="deleteReceptura(${r.id})" title="Usuń składnik">
                            <i class="bi bi-trash"></i>
                        </button>
                    </div>
                </div>
            </div>
        `;
    });
    html += '</div>';
    
    return html;
}

let selectedProduktData = null;
let selectedReceptury = [];

async function onProduktChange() {
    const produktId = document.getElementById('produktSelect').value;
    
    if (!produktId) {
        document.getElementById('produktDetails').style.display = 'none';
        document.getElementById('addProduktBtn').disabled = true;
        return;
    }
    
    // Znajdź produkt
    selectedProduktData = produkty.find(p => p.id === parseInt(produktId));
    
    if (!selectedProduktData) return;
    
    // Pobierz recepturę
    try {
        selectedReceptury = await apiCall(`receptury/${produktId}`);
        
        if (selectedReceptury.length === 0) {
            showToast('Uwaga', 'Ten produkt nie ma zdefiniowanej receptury', 'error');
            document.getElementById('produktDetails').style.display = 'none';
            document.getElementById('addProduktBtn').disabled = true;
            return;
        }
        
        // Pokaż szczegóły produktu
        document.getElementById('produktOpis').textContent = selectedProduktData.opis || 'Brak opisu';
        document.getElementById('produktGramatura').textContent = `${selectedProduktData.gramatura_sloika}g / słoik`;
        
        // Pokaż recepturę
        let recepturaHtml = '<ul class="list-group list-group-sm">';
        selectedReceptury.forEach(r => {
            recepturaHtml += `<li class="list-group-item d-flex justify-content-between align-items-center">
                ${r.surowiec_nazwa}
                <span class="badge bg-primary">${r.ilosc_na_100g}g</span>
            </li>`;
        });
        recepturaHtml += '</ul>';
        document.getElementById('produktReceptura').innerHTML = recepturaHtml;
        
        // Pokaż sekcję szczegółów
        document.getElementById('produktDetails').style.display = 'block';
        document.getElementById('addProduktBtn').disabled = false;
        
        // Oblicz zużycie surowców
        calculateSurowce();
        
    } catch (error) {
        console.error('Error loading receptura:', error);
    }
}

function calculateSurowce() {
    const ilosc = parseInt(document.getElementById('produktIlosc').value) || 0;
    
    if (ilosc <= 0 || !selectedProduktData || selectedReceptury.length === 0) {
        return;
    }
    
    const iloscGram = ilosc * selectedProduktData.gramatura_sloika;
    
    let html = '<ul class="list-group list-group-sm">';
    selectedReceptury.forEach(r => {
        const potrzebna = (r.ilosc_na_100g / 100) * iloscGram;
        const surowiec = surowce.find(s => s.id === r.surowiec_id);
        const dostepne = surowiec ? surowiec.stan_magazynowy : 0;
        const wystarczy = dostepne >= potrzebna;
        const colorClass = wystarczy ? 'success' : 'danger';
        
        html += `<li class="list-group-item d-flex justify-content-between align-items-center">
            ${r.surowiec_nazwa}
            <span class="text-${colorClass}">
                Potrzeba: ${potrzebna.toFixed(1)}g | Dostępne: ${dostepne.toFixed(1)}g
                ${wystarczy ? '<i class="bi bi-check-circle-fill"></i>' : '<i class="bi bi-x-circle-fill"></i>'}
            </span>
        </li>`;
    });
    html += '</ul>';
    
    document.getElementById('produktSurowceList').innerHTML = html;
}

async function addProduktStan() {
    const produktId = document.getElementById('produktSelect').value;
    const ilosc = parseInt(document.getElementById('produktIlosc').value) || 0;
    
    if (!produktId || ilosc <= 0) {
        showToast('Błąd', 'Wybierz produkt i podaj ilość', 'error');
        return;
    }
    
    try {
        // Zwiększ stan produktu przez API update
        const produkt = produkty.find(p => p.id === parseInt(produktId));
        const nowyStan = produkt.stan_magazynowy + ilosc;
        
        await apiCall(`produkty/${produktId}`, 'PUT', {
            stan_magazynowy: nowyStan
        });
        
        document.getElementById('addProduktForm').reset();
        document.getElementById('produktDetails').style.display = 'none';
        document.getElementById('addProduktBtn').disabled = true;
        
        bootstrap.Modal.getInstance(document.getElementById('addProduktModal')).hide();
        
        await loadProdukty();
        await loadAllData();
        showToast('Sukces', `Dodano ${ilosc} szt. produktu ${produkt.nazwa}`, 'success');
    } catch (error) {
        console.error('Error adding produkt stan:', error);
    }
}

function setProduktColor(color) {
    document.getElementById('createProduktKolor').value = color;
}

async function createNewProdukt() {
    const nazwa = document.getElementById('createProduktNazwa').value;
    const opis = document.getElementById('createProduktOpis').value;
    const gramatura = parseFloat(document.getElementById('createProduktGramatura').value) || 100;
    const kolor = document.getElementById('createProduktKolor').value || '#6c757d';
    
    if (!nazwa.trim()) {
        showToast('Błąd', 'Nazwa produktu jest wymagana', 'error');
        return;
    }
    
    if (gramatura <= 0) {
        showToast('Błąd', 'Gramatura słoika musi być większa od 0', 'error');
        return;
    }
    
    try {
        await apiCall('produkty', 'POST', {
            nazwa: nazwa,
            opis: opis,
            stan_magazynowy: 0,
            gramatura_sloika: gramatura,
            kolor_etykiety: kolor
        });
        
        document.getElementById('createProduktForm').reset();
        document.getElementById('createProduktGramatura').value = 100;
        document.getElementById('createProduktKolor').value = '#6c757d';
        
        bootstrap.Modal.getInstance(document.getElementById('createProduktModal')).hide();
        
        await loadProdukty();
        await loadReceptury();
        await loadAllData();
        showToast('Sukces', 'Produkt został utworzony. Teraz możesz dodać składniki receptury.', 'success');
    } catch (error) {
        console.error('Error creating produkt:', error);
    }
}

async function editProdukt(id) {
    const produkt = produkty.find(p => p.id === id);
    if (!produkt) return;
    
    const newStan = prompt(`Nowy stan magazynowy dla ${produkt.nazwa} (szt.):`, produkt.stan_magazynowy);
    if (newStan === null) return;
    
    const newGramatura = prompt(`Gramatura słoika dla ${produkt.nazwa} (g):`, produkt.gramatura_sloika);
    if (newGramatura === null) return;
    
    try {
        await apiCall(`produkty/${id}`, 'PUT', {
            stan_magazynowy: parseInt(newStan) || 0,
            gramatura_sloika: parseFloat(newGramatura) || 100
        });
        
        await loadProdukty();
        await loadAllData();
        showToast('Sukces', 'Produkt został zaktualizowany', 'success');
    } catch (error) {
        console.error('Error updating produkt:', error);
    }
}

async function showAddSkladnikModal(produktId, produktNazwa) {
    // Ustaw ID produktu
    document.getElementById('skladnikProduktId').value = produktId;
    document.getElementById('skladnikProduktNazwa').textContent = produktNazwa;
    
    // Pobierz aktualną recepturę
    const receptury = await apiCall(`receptury/${produktId}`);
    const uzyteSurowceIds = receptury.map(r => r.surowiec_id);
    
    // Wypełnij listę surowców (bez już dodanych)
    const select = document.getElementById('skladnikSurowiec');
    select.innerHTML = '';
    
    let dostepneSurowce = 0;
    surowce.forEach(s => {
        // Pomiń surowce już dodane do receptury
        if (uzyteSurowceIds.includes(s.id)) {
            return;
        }
        
        dostepneSurowce++;
        const option = document.createElement('option');
        option.value = s.id;
        option.textContent = `${s.nazwa} (dostępne: ${s.stan_magazynowy.toFixed(1)}g)`;
        option.setAttribute('data-nazwa', s.nazwa.toLowerCase());
        select.appendChild(option);
    });
    
    // Jeśli nie ma dostępnych surowców
    if (dostepneSurowce === 0) {
        select.innerHTML = '<option value="">Wszystkie surowce zostały już dodane</option>';
        showToast('Info', 'Wszystkie dostępne surowce zostały już dodane do receptury', 'info');
    }
    
    // Wyczyść formularz
    document.getElementById('skladnikIlosc').value = '';
    document.getElementById('skladnikSearch').value = '';
    document.getElementById('skladnikSumaInfo').style.display = 'none';
    
    // Pokaż modal
    const modal = new bootstrap.Modal(document.getElementById('addSkladnikModal'));
    modal.show();
    
    // Oblicz aktualną sumę składników
    calculateSkladnikSum(produktId);
}

function filterSurowce() {
    const searchText = document.getElementById('skladnikSearch').value.toLowerCase();
    const select = document.getElementById('skladnikSurowiec');
    const options = select.getElementsByTagName('option');
    
    for (let i = 0; i < options.length; i++) {
        const option = options[i];
        const nazwa = option.getAttribute('data-nazwa') || '';
        
        if (nazwa.includes(searchText)) {
            option.style.display = '';
        } else {
            option.style.display = 'none';
        }
    }
    
    // Automatycznie wybierz pierwszy widoczny element jeśli jest tylko jeden
    const visibleOptions = Array.from(options).filter(opt => opt.style.display !== 'none');
    if (visibleOptions.length === 1) {
        visibleOptions[0].selected = true;
    }
}

async function calculateSkladnikSum(produktId) {
    try {
        const receptury = await apiCall(`receptury/${produktId}`);
        let suma = 0;
        receptury.forEach(r => {
            suma += r.ilosc_na_100g;
        });
        
        if (receptury.length > 0) {
            document.getElementById('skladnikSuma').textContent = suma.toFixed(1);
            document.getElementById('skladnikSumaInfo').style.display = 'block';
        }
    } catch (error) {
        console.error('Error calculating sum:', error);
    }
}

async function saveSkladnik() {
    const produktId = document.getElementById('skladnikProduktId').value;
    const surowiecId = document.getElementById('skladnikSurowiec').value;
    const ilosc = parseFloat(document.getElementById('skladnikIlosc').value);
    
    if (!surowiecId) {
        showToast('Błąd', 'Wybierz surowiec', 'error');
        return;
    }
    
    if (!ilosc || ilosc <= 0) {
        showToast('Błąd', 'Podaj prawidłową ilość', 'error');
        return;
    }
    
    // Sprawdź czy surowiec już istnieje w recepturze
    try {
        const receptury = await apiCall(`receptury/${produktId}`);
        const juzIstnieje = receptury.find(r => r.surowiec_id === parseInt(surowiecId));
        
        if (juzIstnieje) {
            const surowiec = surowce.find(s => s.id === parseInt(surowiecId));
            showToast('Błąd', `Surowiec "${surowiec.nazwa}" już istnieje w recepturze (${juzIstnieje.ilosc_na_100g}g). Usuń go najpierw, jeśli chcesz zmienić ilość.`, 'error');
            return;
        }
        
        await apiCall('receptury', 'POST', {
            produkt_id: parseInt(produktId),
            surowiec_id: parseInt(surowiecId),
            ilosc_na_100g: ilosc
        });
        
        bootstrap.Modal.getInstance(document.getElementById('addSkladnikModal')).hide();
        await loadReceptury();
        showToast('Sukces', 'Składnik został dodany do receptury', 'success');
    } catch (error) {
        console.error('Error adding receptura:', error);
        showToast('Błąd', 'Nie udało się dodać składnika', 'error');
    }
}

async function deleteReceptura(recepturaId) {
    if (!confirm('Czy na pewno chcesz usunąć ten składnik z receptury?')) {
        return;
    }
    
    try {
        await apiCall(`receptury/${recepturaId}`, 'DELETE');
        await loadReceptury();
        showToast('Sukces', 'Składnik został usunięty z receptury', 'success');
    } catch (error) {
        console.error('Error deleting receptura:', error);
    }
}

// Dostawy functions
async function loadDostawy() {
    try {
        dostawy = await apiCall('dostawy');
        renderDostawyTable();
    } catch (error) {
        console.error('Error loading dostawy:', error);
    }
}

function renderDostawyTable() {
    const tbody = document.getElementById('dostawyTable');
    
    if (dostawy.length === 0) {
        tbody.innerHTML = '<tr><td colspan="5" class="text-center text-muted">Brak dostaw</td></tr>';
        return;
    }
    
    let html = '';
    dostawy.forEach(dostawa => {
        html += `
            <tr>
                <td>${dostawa.data}</td>
                <td>${dostawa.surowiec_nazwa}</td>
                <td>${dostawa.ilosc.toFixed(1)}</td>
                <td>${dostawa.cena_calkowita.toFixed(2)}</td>
                <td>${dostawa.cena_za_gram.toFixed(3)}</td>
            </tr>
        `;
    });
    tbody.innerHTML = html;
}

async function addDostawa() {
    const surowiecId = document.getElementById('dostawa_surowiec').value;
    const ilosc = parseFloat(document.getElementById('dostawa_ilosc').value);
    const cena = parseFloat(document.getElementById('dostawa_cena').value) || 0;
    
    if (!surowiecId || !ilosc) {
        showToast('Błąd', 'Surowiec i ilość są wymagane', 'error');
        return;
    }
    
    try {
        await apiCall('dostawy', 'POST', {
            surowiec_id: parseInt(surowiecId),
            ilosc: ilosc,
            cena_calkowita: cena
        });
        
        document.getElementById('addDostawaForm').reset();
        bootstrap.Modal.getInstance(document.getElementById('addDostawaModal')).hide();
        
        await loadDostawy();
        await loadAllData();
        showToast('Sukces', 'Dostawa została zarejestrowana', 'success');
    } catch (error) {
        console.error('Error adding dostawa:', error);
    }
}

// Produkcja functions
async function loadProdukcja() {
    try {
        produkcje = await apiCall('produkcja');
        renderProdukcjaTable();
    } catch (error) {
        console.error('Error loading produkcja:', error);
    }
}

function renderProdukcjaTable() {
    const tbody = document.getElementById('produkcjaTable');
    
    if (produkcje.length === 0) {
        tbody.innerHTML = '<tr><td colspan="3" class="text-center text-muted">Brak produkcji</td></tr>';
        return;
    }
    
    let html = '';
    produkcje.forEach(produkcja => {
        html += `
            <tr>
                <td>${produkcja.data}</td>
                <td>${produkcja.produkt_nazwa}</td>
                <td>${produkcja.ilosc.toFixed(1)}</td>
            </tr>
        `;
    });
    tbody.innerHTML = html;
}

async function addProdukcja() {
    const produktId = document.getElementById('produkcja_produkt').value;
    const ilosc = parseFloat(document.getElementById('produkcja_ilosc').value);
    
    if (!produktId || !ilosc) {
        showToast('Błąd', 'Produkt i ilość są wymagane', 'error');
        return;
    }
    
    try {
        await apiCall('produkcja', 'POST', {
            produkt_id: parseInt(produktId),
            ilosc: ilosc
        });
        
        document.getElementById('addProdukcjaForm').reset();
        bootstrap.Modal.getInstance(document.getElementById('addProdukcjaModal')).hide();
        
        await loadProdukcja();
        await loadAllData();
        showToast('Sukces', 'Produkcja została zarejestrowana', 'success');
    } catch (error) {
        console.error('Error adding produkcja:', error);
    }
}

// Utility functions
function populateSelects() {
    // Populate surowce select in dostawa modal
    const dostawaSelect = document.getElementById('dostawa_surowiec');
    dostawaSelect.innerHTML = '<option value="">Wybierz surowiec...</option>';
    surowce.forEach(s => {
        dostawaSelect.innerHTML += `<option value="${s.id}">${s.nazwa}</option>`;
    });
    
    // Populate produkty select in produkcja modal
    const produkcjaSelect = document.getElementById('produkcja_produkt');
    produkcjaSelect.innerHTML = '<option value="">Wybierz produkt...</option>';
    produkty.forEach(p => {
        produkcjaSelect.innerHTML += `<option value="${p.id}">${p.nazwa}</option>`;
    });
    
    // Populate produkty select in add produkt modal
    const produktSelect = document.getElementById('produktSelect');
    produktSelect.innerHTML = '<option value="">-- Wybierz produkt z receptury --</option>';
    produkty.forEach(p => {
        produktSelect.innerHTML += `<option value="${p.id}">${p.nazwa}</option>`;
    });
}

function showToast(title, message, type = 'info') {
    // Create toast container if it doesn't exist
    let container = document.querySelector('.toast-container');
    if (!container) {
        container = document.createElement('div');
        container.className = 'toast-container';
        document.body.appendChild(container);
    }
    
    const toastId = 'toast-' + Date.now();
    const bgClass = type === 'success' ? 'bg-success' : type === 'error' ? 'bg-danger' : 'bg-info';
    
    const toastHtml = `
        <div id="${toastId}" class="toast ${bgClass} text-white" role="alert">
            <div class="toast-header">
                <strong class="me-auto">${title}</strong>
                <button type="button" class="btn-close btn-close-white" data-bs-dismiss="toast"></button>
            </div>
            <div class="toast-body">
                ${message}
            </div>
        </div>
    `;
    
    container.insertAdjacentHTML('beforeend', toastHtml);
    
    const toastElement = document.getElementById(toastId);
    const toast = new bootstrap.Toast(toastElement);
    toast.show();
    
    // Remove toast element after it's hidden
    toastElement.addEventListener('hidden.bs.toast', function() {
        toastElement.remove();
    });
}

// Historia functions
async function showHistoriaSurowcow() {
    try {
        const historia = await apiCall('historia/surowce');
        renderHistoriaSurowcow(historia);
        const modal = new bootstrap.Modal(document.getElementById('historiaSurowcowModal'));
        modal.show();
    } catch (error) {
        console.error('Error loading historia surowcow:', error);
    }
}

function renderHistoriaSurowcow(historia) {
    const tbody = document.getElementById('historiaSurowcowTable');
    
    if (historia.length === 0) {
        tbody.innerHTML = '<tr><td colspan="8" class="text-center text-muted">Brak historii</td></tr>';
        return;
    }
    
    let html = '';
    historia.forEach(h => {
        const zmianaClass = h.zmiana > 0 ? 'text-success' : 'text-danger';
        const zmianaIcon = h.zmiana > 0 ? '↑' : '↓';
        html += `
            <tr>
                <td><small>${h.data}</small></td>
                <td>${h.surowiec_nazwa}</td>
                <td><span class="badge bg-secondary">${h.typ_operacji}</span></td>
                <td class="${zmianaClass}">${zmianaIcon} ${Math.abs(h.zmiana).toFixed(1)}g</td>
                <td>${h.stan_przed.toFixed(1)}g</td>
                <td>${h.stan_po.toFixed(1)}g</td>
                <td><small>${h.opis || '-'}</small></td>
                <td>
                    <button class="btn btn-sm btn-outline-danger" onclick="deleteHistoriaSurowcow(${h.id})" title="Cofnij operację">
                        <i class="bi bi-arrow-counterclockwise"></i>
                    </button>
                </td>
            </tr>
        `;
    });
    tbody.innerHTML = html;
}

async function deleteHistoriaSurowcow(id) {
    if (!confirm('Czy na pewno chcesz cofnąć tę operację? Stan magazynowy zostanie przywrócony do stanu sprzed operacji.')) {
        return;
    }
    
    try {
        const result = await apiCall(`historia/surowce/${id}`, 'DELETE');
        showToast('Sukces', `Operacja została cofnięta. Nowy stan: ${result.nowy_stan.toFixed(1)}g`, 'success');
        await showHistoriaSurowcow(); // Odśwież historię
        await loadSurowce(); // Odśwież tabelę surowców
        await loadAllData(); // Odśwież wszystkie dane
    } catch (error) {
        console.error('Error deleting historia:', error);
    }
}

async function showHistoriaProduktow() {
    try {
        const historia = await apiCall('historia/produkty');
        renderHistoriaProduktow(historia);
        const modal = new bootstrap.Modal(document.getElementById('historiaProduktowModal'));
        modal.show();
    } catch (error) {
        console.error('Error loading historia produktow:', error);
    }
}

function renderHistoriaProduktow(historia) {
    const tbody = document.getElementById('historiaProduktowTable');
    
    if (historia.length === 0) {
        tbody.innerHTML = '<tr><td colspan="8" class="text-center text-muted">Brak historii</td></tr>';
        return;
    }
    
    let html = '';
    historia.forEach(h => {
        const zmianaClass = h.zmiana > 0 ? 'text-success' : 'text-danger';
        const zmianaIcon = h.zmiana > 0 ? '↑' : '↓';
        html += `
            <tr>
                <td><small>${h.data}</small></td>
                <td>${h.produkt_nazwa}</td>
                <td><span class="badge bg-secondary">${h.typ_operacji}</span></td>
                <td class="${zmianaClass}">${zmianaIcon} ${Math.abs(h.zmiana)} szt.</td>
                <td>${h.stan_przed} szt.</td>
                <td>${h.stan_po} szt.</td>
                <td><small>${h.opis || '-'}</small></td>
                <td>
                    <button class="btn btn-sm btn-outline-danger" onclick="deleteHistoriaProduktow(${h.id})" title="Cofnij operację">
                        <i class="bi bi-arrow-counterclockwise"></i>
                    </button>
                </td>
            </tr>
        `;
    });
    tbody.innerHTML = html;
}

async function deleteHistoriaProduktow(id) {
    if (!confirm('Czy na pewno chcesz cofnąć tę operację? Stan magazynowy zostanie przywrócony do stanu sprzed operacji.')) {
        return;
    }
    
    try {
        const result = await apiCall(`historia/produkty/${id}`, 'DELETE');
        showToast('Sukces', `Operacja została cofnięta. Nowy stan: ${result.nowy_stan} szt.`, 'success');
        await showHistoriaProduktow(); // Odśwież historię
        await loadProdukty(); // Odśwież tabelę produktów
        await loadAllData(); // Odśwież wszystkie dane
    } catch (error) {
        console.error('Error deleting historia:', error);
    }
}

// Korekta manualna produktu
function openKorektaProdukt(produktId) {
    const produkt = produkty.find(p => p.id === produktId);
    if (!produkt) return;
    
    document.getElementById('korektaProduktId').value = produkt.id;
    document.getElementById('korektaProduktNazwa').textContent = produkt.nazwa;
    document.getElementById('korektaProduktStanAktualny').textContent = `${produkt.stan_magazynowy} szt.`;
    document.getElementById('korektaNowyStan').value = produkt.stan_magazynowy;
    document.getElementById('korektaPowodSelect').value = '';
    document.getElementById('korektaPowod').value = '';
    
    const modal = new bootstrap.Modal(document.getElementById('korektaProduktModal'));
    modal.show();
}

function updateKorektaPowod() {
    const select = document.getElementById('korektaPowodSelect');
    const textarea = document.getElementById('korektaPowod');
    
    if (select.value && select.value !== 'Inny') {
        textarea.value = select.value;
    } else if (select.value === 'Inny') {
        textarea.value = '';
        textarea.focus();
    }
}

async function saveKorektaProdukt() {
    const produktId = document.getElementById('korektaProduktId').value;
    const nowyStan = parseInt(document.getElementById('korektaNowyStan').value);
    const powod = document.getElementById('korektaPowod').value.trim();
    
    if (!powod) {
        alert('Proszę podać powód korekty');
        return;
    }
    
    if (nowyStan < 0) {
        alert('Stan nie może być ujemny');
        return;
    }
    
    try {
        const result = await apiCall(`produkty/${produktId}/korekta`, 'POST', {
            nowy_stan: nowyStan,
            powod: powod
        });
        
        showToast('Sukces', result.message, 'success');
        
        // Zamknij modal
        const modal = bootstrap.Modal.getInstance(document.getElementById('korektaProduktModal'));
        modal.hide();
        
        // Odśwież dane
        await loadProdukty();
        await loadAllData();
    } catch (error) {
        console.error('Error saving korekta:', error);
        alert('Błąd podczas zapisywania korekty: ' + error.message);
    }
}

// Korekta manualna surowca
function openKorektaSurowiec(surowiecId) {
    const surowiec = surowce.find(s => s.id === surowiecId);
    if (!surowiec) return;
    
    document.getElementById('korektaSurowiecId').value = surowiec.id;
    document.getElementById('korektaSurowiecNazwa').textContent = surowiec.nazwa;
    document.getElementById('korektaSurowiecStanAktualny').textContent = `${surowiec.stan_magazynowy.toFixed(1)}g`;
    document.getElementById('korektaSurowiecNowyStan').value = surowiec.stan_magazynowy;
    document.getElementById('korektaSurowiecPowodSelect').value = '';
    document.getElementById('korektaSurowiecPowod').value = '';
    
    const modal = new bootstrap.Modal(document.getElementById('korektaSurowiecModal'));
    modal.show();
}

function updateKorektaSurowiecPowod() {
    const select = document.getElementById('korektaSurowiecPowodSelect');
    const textarea = document.getElementById('korektaSurowiecPowod');
    
    if (select.value && select.value !== 'Inny') {
        textarea.value = select.value;
    } else if (select.value === 'Inny') {
        textarea.value = '';
        textarea.focus();
    }
}

async function saveKorektaSurowiec() {
    const surowiecId = document.getElementById('korektaSurowiecId').value;
    const nowyStan = parseFloat(document.getElementById('korektaSurowiecNowyStan').value);
    const powod = document.getElementById('korektaSurowiecPowod').value.trim();
    
    if (!powod) {
        alert('Proszę podać powód korekty');
        return;
    }
    
    if (nowyStan < 0) {
        alert('Stan nie może być ujemny');
        return;
    }
    
    try {
        const result = await apiCall(`surowce/${surowiecId}/korekta`, 'POST', {
            nowy_stan: nowyStan,
            powod: powod
        });
        
        showToast('Sukces', result.message, 'success');
        
        // Zamknij modal
        const modal = bootstrap.Modal.getInstance(document.getElementById('korektaSurowiecModal'));
        modal.hide();
        
        // Odśwież dane
        await loadSurowce();
        await loadAllData();
    } catch (error) {
        console.error('Error saving korekta:', error);
        alert('Błąd podczas zapisywania korekty: ' + error.message);
    }
}

// Edycja koloru etykiety
function openEditKolorModal(produktId, produktNazwa, kolorEtykiety) {
    document.getElementById('editKolorProduktId').value = produktId;
    document.getElementById('editKolorProduktNazwa').textContent = produktNazwa;
    document.getElementById('editKolorEtykiety').value = kolorEtykiety;
    updateEditKolorPodglad(kolorEtykiety);
    
    const modal = new bootstrap.Modal(document.getElementById('editKolorModal'));
    modal.show();
}

function setEditKolorColor(color) {
    document.getElementById('editKolorEtykiety').value = color;
    updateEditKolorPodglad(color);
}

function updateEditKolorPodglad(color) {
    const podglad = document.getElementById('editKolorPodglad');
    podglad.style.backgroundColor = color;
    
    // Oblicz jasność koloru, aby wybrać odpowiedni kolor tekstu
    const rgb = parseInt(color.slice(1), 16);
    const r = (rgb >> 16) & 0xff;
    const g = (rgb >>  8) & 0xff;
    const b = (rgb >>  0) & 0xff;
    const brightness = (r * 299 + g * 587 + b * 114) / 1000;
    podglad.style.color = brightness > 128 ? '#000000' : '#ffffff';
}

// Dodaj listener do color pickera
document.addEventListener('DOMContentLoaded', function() {
    const colorInput = document.getElementById('editKolorEtykiety');
    if (colorInput) {
        colorInput.addEventListener('input', function() {
            updateEditKolorPodglad(this.value);
        });
    }
});

async function saveEditKolor() {
    const produktId = document.getElementById('editKolorProduktId').value;
    const nowyKolor = document.getElementById('editKolorEtykiety').value;
    
    try {
        await apiCall(`produkty/${produktId}`, 'PUT', {
            kolor_etykiety: nowyKolor
        });
        
        showToast('Sukces', 'Kolor etykiety został zmieniony', 'success');
        
        // Zamknij modal
        const modal = bootstrap.Modal.getInstance(document.getElementById('editKolorModal'));
        modal.hide();
        
        // Odśwież receptury
        await loadReceptury();
        await loadProdukty();
    } catch (error) {
        console.error('Error saving kolor:', error);
        alert('Błąd podczas zapisywania koloru: ' + error.message);
    }
}

// Usuwanie surowca
async function deleteSurowiec(id, nazwa) {
    if (!confirm(`Czy na pewno chcesz usunąć surowiec "${nazwa}"?\n\nUWAGA: Nie można usunąć surowca, który jest używany w recepturach.`)) {
        return;
    }
    
    try {
        const result = await apiCall(`surowce/${id}`, 'DELETE');
        showToast('Sukces', result.message, 'success');
        await loadSurowce();
        await loadAllData();
    } catch (error) {
        console.error('Error deleting surowiec:', error);
        // Błąd jest już wyświetlony przez apiCall
    }
}

// Usuwanie produktu z zakładki Produkty
async function deleteProdukt(id, nazwa) {
    if (!confirm(`Czy na pewno chcesz usunąć produkt "${nazwa}"?\n\nUWAGA: Zostanie usunięta również receptura i historia tego produktu.`)) {
        return;
    }
    
    try {
        const result = await apiCall(`produkty/${id}`, 'DELETE');
        showToast('Sukces', result.message, 'success');
        await loadProdukty();
        await loadReceptury();
        await loadAllData();
    } catch (error) {
        console.error('Error deleting produkt:', error);
        // Błąd jest już wyświetlony przez apiCall
    }
}

// Usuwanie produktu z zakładki Receptury
async function deleteProduktFromReceptura(id, nazwa) {
    if (!confirm(`Czy na pewno chcesz usunąć produkt "${nazwa}" wraz z recepturą?\n\nUWAGA: Ta operacja jest nieodwracalna!`)) {
        return;
    }
    
    try {
        const result = await apiCall(`produkty/${id}`, 'DELETE');
        showToast('Sukces', result.message, 'success');
        await loadReceptury();
        await loadProdukty();
        await loadAllData();
    } catch (error) {
        console.error('Error deleting produkt:', error);
        // Błąd jest już wyświetlony przez apiCall
    }
}

// Pokazywanie szczegółów surowców dla produktu
function showSurowceDetails(produktId) {
    const produkt = produkty.find(p => p.id === produktId);
    if (!produkt || !produkt.surowce_details) {
        return;
    }
    
    // Sortuj surowce według max_sloikow (rosnąco) - ograniczający na górze
    const sortedDetails = [...produkt.surowce_details].sort((a, b) => a.max_sloikow - b.max_sloikow);
    
    let tableHtml = `
        <div class="table-responsive">
            <table class="table table-sm table-hover">
                <thead>
                    <tr>
                        <th>Surowiec</th>
                        <th>Stan dostępny</th>
                        <th>Zużycie na słoik</th>
                        <th>Wystarczy na</th>
                    </tr>
                </thead>
                <tbody>
    `;
    
    sortedDetails.forEach((detail, index) => {
        const isLimiting = index === 0; // Pierwszy (najmniejszy) jest ograniczający
        const rowClass = isLimiting ? 'table-danger' : '';
        const badge = isLimiting ? '<span class="badge bg-danger ms-2">Ogranicza</span>' : '';
        
        tableHtml += `
            <tr class="${rowClass}">
                <td><strong>${detail.nazwa}</strong>${badge}</td>
                <td>${detail.stan_dostepny}g</td>
                <td>${detail.ilosc_na_sloik}g</td>
                <td><strong>${detail.max_sloikow} szt.</strong></td>
            </tr>
        `;
    });
    
    tableHtml += `
                </tbody>
            </table>
        </div>
        <div class="alert alert-info mt-3 mb-0">
            <i class="bi bi-info-circle"></i> 
            <strong>Maksymalna produkcja: ${produkt.max_produkcja} szt.</strong><br>
            <small>Ograniczony przez: <strong>${produkt.ograniczajacy_surowiec}</strong></small>
        </div>
    `;
    
    // Ustaw zawartość modalu
    document.getElementById('surowceDetailsModalLabel').textContent = `Szczegóły surowców - ${produkt.nazwa}`;
    document.getElementById('surowceDetailsContent').innerHTML = tableHtml;
    
    // Pokaż modal
    const modal = new bootstrap.Modal(document.getElementById('surowceDetailsModal'));
    modal.show();
}
