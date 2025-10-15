// Funkcje pomocnicze dla tabel - zaznaczanie i sortowanie

// Globalna zmienna do przechowywania zaznaczonych rzędów
let selectedRows = new Set();
let tableListenersInitialized = false;

/**
 * Inicjalizuje zaznaczanie rzędów w tabeli
 * @param {string} tableId - ID tabeli (np. 'surowceTable')
 */
function initRowSelection(tableId) {
    // Jeśli już zainicjalizowano globalny listener, nie dodawaj więcej
    if (tableListenersInitialized) return;
    
    // Użyj delegacji zdarzeń na poziomie dokumentu
    document.addEventListener('click', function(e) {
        // Sprawdź czy kliknięto w tabelę
        const table = e.target.closest('tbody');
        if (!table || (table.id !== 'surowceTable' && table.id !== 'produktyTable')) {
            return;
        }
        
        // Znajdź najbliższy tr (rząd)
        const row = e.target.closest('tr');
        if (!row) return;

        // Nie zaznaczaj jeśli kliknięto przycisk, input, link lub ikonę
        if (e.target.closest('button') || e.target.closest('input') || e.target.closest('a') || e.target.closest('i.bi-info-circle')) {
            return;
        }

        // Zaznacz tylko ten rząd (odznacz wszystkie inne)
        toggleRowSelection(row, table);
    });
    
    tableListenersInitialized = true;
}

/**
 * Przełącza zaznaczenie rzędu (tylko jeden na raz)
 * @param {HTMLElement} row - Element tr
 * @param {HTMLElement} table - Element tbody
 */
function toggleRowSelection(row, table) {
    // Sprawdź czy ten rząd jest już zaznaczony
    const wasSelected = row.classList.contains('selected');
    
    // Odznacz wszystkie rzędy w tej tabeli
    const allRows = table.querySelectorAll('tr');
    allRows.forEach(r => {
        r.classList.remove('selected');
        selectedRows.delete(r);
    });
    
    // Jeśli rząd nie był zaznaczony, zaznacz go
    if (!wasSelected) {
        row.classList.add('selected');
        selectedRows.add(row);
    }
}

/**
 * Czyści wszystkie zaznaczenia
 */
function clearAllSelections() {
    selectedRows.forEach(row => {
        row.classList.remove('selected');
    });
    selectedRows.clear();
}

/**
 * Pobiera dane z zaznaczonych rzędów
 * @returns {Array} Tablica z danymi zaznaczonych rzędów
 */
function getSelectedRowsData() {
    const data = [];
    selectedRows.forEach(row => {
        const cells = row.querySelectorAll('td');
        const rowData = {};
        cells.forEach((cell, index) => {
            rowData[`col${index}`] = cell.textContent.trim();
        });
        data.push(rowData);
    });
    return data;
}

/**
 * Sortuje tabelę według kolumny
 * @param {string} tableId - ID tabeli
 * @param {number} columnIndex - Indeks kolumny do sortowania
 * @param {string} type - Typ danych ('number', 'text', 'date')
 * @param {boolean} ascending - Kierunek sortowania
 */
function sortTable(tableId, columnIndex, type = 'text', ascending = true) {
    const tbody = document.getElementById(tableId);
    if (!tbody) return;

    const rows = Array.from(tbody.querySelectorAll('tr'));
    
    rows.sort((a, b) => {
        const aCell = a.cells[columnIndex];
        const bCell = b.cells[columnIndex];
        
        if (!aCell || !bCell) return 0;

        let aVal = aCell.textContent.trim();
        let bVal = bCell.textContent.trim();

        // Konwersja wartości w zależności od typu
        if (type === 'number') {
            // Usuń wszystko oprócz cyfr, kropek i minusów
            aVal = parseFloat(aVal.replace(/[^\d.-]/g, '')) || 0;
            bVal = parseFloat(bVal.replace(/[^\d.-]/g, '')) || 0;
        } else if (type === 'date') {
            aVal = new Date(aVal).getTime() || 0;
            bVal = new Date(bVal).getTime() || 0;
        }

        let comparison = 0;
        if (type === 'number' || type === 'date') {
            comparison = aVal - bVal;
        } else {
            comparison = aVal.localeCompare(bVal, 'pl');
        }

        return ascending ? comparison : -comparison;
    });

    // Usuń wszystkie rzędy
    rows.forEach(row => tbody.removeChild(row));
    
    // Dodaj posortowane rzędy
    rows.forEach(row => tbody.appendChild(row));
}

/**
 * Dodaje sortowanie do nagłówka tabeli
 * @param {string} headerId - ID nagłówka (th)
 * @param {string} tableId - ID tabeli (tbody)
 * @param {number} columnIndex - Indeks kolumny
 * @param {string} type - Typ danych
 */
function makeSortable(headerId, tableId, columnIndex, type = 'text') {
    const header = document.getElementById(headerId);
    if (!header) return;

    header.classList.add('sortable');
    
    // Zmienna przechowująca stan sortowania dla tego nagłówka
    let isAscending = true;

    header.addEventListener('click', function() {
        // Usuń klasy sortowania z innych nagłówków
        const allHeaders = header.closest('thead').querySelectorAll('th.sortable');
        allHeaders.forEach(h => {
            if (h !== header) {
                h.classList.remove('asc', 'desc');
            }
        });

        // Ustaw klasy CSS w zależności od kierunku
        if (isAscending) {
            header.classList.remove('desc');
            header.classList.add('asc');
        } else {
            header.classList.remove('asc');
            header.classList.add('desc');
        }

        // Wykonaj sortowanie
        sortTable(tableId, columnIndex, type, isAscending);

        // Przełącz kierunek dla następnego kliknięcia
        isAscending = !isAscending;
    });
}

/**
 * Automatycznie inicjalizuje sortowanie dla wszystkich tabel
 */
function autoInitSorting() {
    // Surowce - sortowanie po stanie magazynowym (kolumna 1 - Stan (g))
    makeSortable('surowceStanHeader', 'surowceTable', 1, 'number');
    
    // Produkty - sortowanie po stanie magazynowym (kolumna 2 - Stan (szt.)) - przesunięte o 1 przez checkbox
    makeSortable('produktyStanHeader', 'produktyTable', 2, 'number');
    
    // Produkty - sortowanie po maksymalnej produkcji (kolumna 5 - Maks. produkcja) - przesunięte o 1 przez checkbox
    makeSortable('produktyMaxProdHeader', 'produktyTable', 5, 'number');
}

// Inicjalizacja po załadowaniu DOM
document.addEventListener('DOMContentLoaded', function() {
    // Inicjalizuj zaznaczanie dla wszystkich tabel
    initRowSelection('surowceTable');
    initRowSelection('produktyTable');
    
    // Poczekaj chwilę na załadowanie danych, potem inicjalizuj sortowanie
    setTimeout(autoInitSorting, 1000);
});
