from flask import Flask, render_template, request, jsonify
from flask_sqlalchemy import SQLAlchemy
from flask_cors import CORS
from datetime import datetime
import os
import hmac
import hashlib
import json
import logging
from dotenv import load_dotenv

# Wczytaj zmienne środowiskowe z pliku .env
load_dotenv()

# Konfiguracja logowania do pliku
logging.basicConfig(
    level=logging.DEBUG,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler('webhook_debug.log'),
        logging.StreamHandler()
    ]
)
logger = logging.getLogger(__name__)

app = Flask(__name__)
app.config['SQLALCHEMY_DATABASE_URI'] = 'sqlite:///magazyn.db'
app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False
app.config['WOOCOMMERCE_SECRET'] = os.getenv('WOOCOMMERCE_SECRET', '')
CORS(app)

db = SQLAlchemy(app)

# Modele bazy danych
class Surowiec(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    nazwa = db.Column(db.String(100), nullable=False, unique=True)
    stan_magazynowy = db.Column(db.Float, default=0.0)  # w gramach
    cena_jednostkowa = db.Column(db.Float, default=0.0)  # za gram
    
    def to_dict(self):
        return {
            'id': self.id,
            'nazwa': self.nazwa,
            'stan_magazynowy': self.stan_magazynowy,
            'cena_jednostkowa': self.cena_jednostkowa,
            'wartosc_magazynowa': self.stan_magazynowy * self.cena_jednostkowa
        }

class Produkt(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    nazwa = db.Column(db.String(100), nullable=False, unique=True)
    opis = db.Column(db.Text)
    stan_magazynowy = db.Column(db.Integer, default=0)  # w sztukach (słoikach)
    gramatura_sloika = db.Column(db.Float, default=100.0)  # ile gramów w jednym słoiku
    kolor_etykiety = db.Column(db.String(7), default='#6c757d')  # kolor hex dla łatwiejszego rozpoznawania
    
    def to_dict(self):
        return {
            'id': self.id,
            'nazwa': self.nazwa,
            'opis': self.opis,
            'stan_magazynowy': self.stan_magazynowy,
            'gramatura_sloika': self.gramatura_sloika,
            'stan_w_gramach': self.stan_magazynowy * self.gramatura_sloika,
            'kolor_etykiety': self.kolor_etykiety
        }

class Receptura(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    produkt_id = db.Column(db.Integer, db.ForeignKey('produkt.id'), nullable=False)
    surowiec_id = db.Column(db.Integer, db.ForeignKey('surowiec.id'), nullable=False)
    ilosc_na_100g = db.Column(db.Float, nullable=False)  # ile gramów surowca na 100g produktu
    
    produkt = db.relationship('Produkt', backref='receptury')
    surowiec = db.relationship('Surowiec', backref='receptury')
    
    def to_dict(self):
        return {
            'id': self.id,
            'produkt_id': self.produkt_id,
            'surowiec_id': self.surowiec_id,
            'surowiec_nazwa': self.surowiec.nazwa,
            'ilosc_na_100g': self.ilosc_na_100g
        }

class Dostawa(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    data = db.Column(db.DateTime, nullable=False, default=datetime.utcnow)
    surowiec_id = db.Column(db.Integer, db.ForeignKey('surowiec.id'), nullable=False)
    ilosc = db.Column(db.Float, nullable=False)  # w gramach
    cena_calkowita = db.Column(db.Float, default=0.0)
    
    surowiec = db.relationship('Surowiec', backref='dostawy')
    
    def to_dict(self):
        return {
            'id': self.id,
            'data': self.data.strftime('%Y-%m-%d %H:%M'),
            'surowiec_id': self.surowiec_id,
            'surowiec_nazwa': self.surowiec.nazwa,
            'ilosc': self.ilosc,
            'cena_calkowita': self.cena_calkowita,
            'cena_za_gram': self.cena_calkowita / self.ilosc if self.ilosc > 0 else 0
        }

class Produkcja(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    data = db.Column(db.DateTime, nullable=False, default=datetime.utcnow)
    produkt_id = db.Column(db.Integer, db.ForeignKey('produkt.id'), nullable=False)
    ilosc = db.Column(db.Float, nullable=False)  # w gramach
    
    produkt = db.relationship('Produkt', backref='produkcje')
    
    def to_dict(self):
        return {
            'id': self.id,
            'data': self.data.strftime('%Y-%m-%d %H:%M'),
            'produkt_id': self.produkt_id,
            'produkt_nazwa': self.produkt.nazwa,
            'ilosc': self.ilosc
        }

class HistoriaSurowcow(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    data = db.Column(db.DateTime, nullable=False, default=datetime.utcnow)
    surowiec_id = db.Column(db.Integer, db.ForeignKey('surowiec.id'), nullable=False)
    typ_operacji = db.Column(db.String(50), nullable=False)  # 'dodanie', 'dostawa', 'produkcja', 'korekta'
    zmiana = db.Column(db.Float, nullable=False)  # dodatnia lub ujemna wartość zmiany
    stan_przed = db.Column(db.Float, nullable=False)
    stan_po = db.Column(db.Float, nullable=False)
    opis = db.Column(db.Text)
    
    surowiec = db.relationship('Surowiec', backref='historia')
    
    def to_dict(self):
        return {
            'id': self.id,
            'data': self.data.strftime('%Y-%m-%d %H:%M:%S'),
            'surowiec_id': self.surowiec_id,
            'surowiec_nazwa': self.surowiec.nazwa,
            'typ_operacji': self.typ_operacji,
            'zmiana': self.zmiana,
            'stan_przed': self.stan_przed,
            'stan_po': self.stan_po,
            'opis': self.opis
        }

class HistoriaProduktow(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    data = db.Column(db.DateTime, nullable=False, default=datetime.utcnow)
    produkt_id = db.Column(db.Integer, db.ForeignKey('produkt.id'), nullable=False)
    typ_operacji = db.Column(db.String(50), nullable=False)  # 'dodanie', 'produkcja', 'korekta'
    zmiana = db.Column(db.Integer, nullable=False)  # dodatnia lub ujemna wartość zmiany (w sztukach)
    stan_przed = db.Column(db.Integer, nullable=False)
    stan_po = db.Column(db.Integer, nullable=False)
    opis = db.Column(db.Text)
    
    produkt = db.relationship('Produkt', backref='historia')
    
    def to_dict(self):
        return {
            'id': self.id,
            'data': self.data.strftime('%Y-%m-%d %H:%M:%S'),
            'produkt_id': self.produkt_id,
            'produkt_nazwa': self.produkt.nazwa,
            'typ_operacji': self.typ_operacji,
            'zmiana': self.zmiana,
            'stan_przed': self.stan_przed,
            'stan_po': self.stan_po,
            'opis': self.opis
        }

class CyklProdukcyjny(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    nazwa = db.Column(db.String(200), nullable=False)
    data_utworzenia = db.Column(db.DateTime, nullable=False, default=datetime.utcnow)
    data_wykonania = db.Column(db.DateTime)
    status = db.Column(db.String(50), nullable=False, default='planowany')  # 'planowany', 'wykonany'
    
    def to_dict(self):
        pozycje = CyklPozycja.query.filter_by(cykl_id=self.id).all()
        return {
            'id': self.id,
            'nazwa': self.nazwa,
            'data_utworzenia': self.data_utworzenia.strftime('%Y-%m-%d %H:%M:%S'),
            'data_wykonania': self.data_wykonania.strftime('%Y-%m-%d %H:%M:%S') if self.data_wykonania else None,
            'status': self.status,
            'pozycje': [p.to_dict() for p in pozycje]
        }

class CyklPozycja(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    cykl_id = db.Column(db.Integer, db.ForeignKey('cykl_produkcyjny.id'), nullable=False)
    produkt_id = db.Column(db.Integer, db.ForeignKey('produkt.id'), nullable=False)
    ilosc = db.Column(db.Integer, nullable=False)  # ilość sztuk do wyprodukowania
    
    cykl = db.relationship('CyklProdukcyjny', backref='pozycje')
    produkt = db.relationship('Produkt')
    
    def to_dict(self):
        return {
            'id': self.id,
            'cykl_id': self.cykl_id,
            'produkt_id': self.produkt_id,
            'produkt_nazwa': self.produkt.nazwa,
            'produkt_gramatura': self.produkt.gramatura_sloika,
            'ilosc': self.ilosc
        }

class WooCommerceMapowanie(db.Model):
    """Mapowanie produktów WooCommerce na produkty magazynowe"""
    id = db.Column(db.Integer, primary_key=True)
    woocommerce_product_id = db.Column(db.Integer, nullable=False, unique=True)
    produkt_id = db.Column(db.Integer, db.ForeignKey('produkt.id'), nullable=False)
    data_utworzenia = db.Column(db.DateTime, nullable=False, default=datetime.utcnow)
    
    produkt = db.relationship('Produkt')
    
    def to_dict(self):
        return {
            'id': self.id,
            'woocommerce_product_id': self.woocommerce_product_id,
            'produkt_id': self.produkt_id,
            'produkt_nazwa': self.produkt.nazwa,
            'data_utworzenia': self.data_utworzenia.strftime('%Y-%m-%d %H:%M:%S')
        }

# Inicjalizacja bazy danych
def create_tables():
    db.create_all()
    
    # Migracja: dodaj kolumnę kolor_etykiety jeśli nie istnieje
    try:
        with db.engine.connect() as conn:
            # Sprawdź czy kolumna istnieje
            result = conn.execute(db.text("PRAGMA table_info(produkt)"))
            columns = [row[1] for row in result]
            
            if 'kolor_etykiety' not in columns:
                # Dodaj kolumnę
                conn.execute(db.text("ALTER TABLE produkt ADD COLUMN kolor_etykiety VARCHAR(7) DEFAULT '#6c757d'"))
                conn.commit()
                print("✅ Dodano kolumnę kolor_etykiety do tabeli produkt")
    except Exception as e:
        print(f"Migracja kolor_etykiety: {e}")
    
    # Dodaj przykładowe dane jeśli baza jest pusta
    if Surowiec.query.count() == 0:
        surowce = [
            Surowiec(nazwa='Papryka słodka', stan_magazynowy=1000.0, cena_jednostkowa=0.02),
            Surowiec(nazwa='Sól', stan_magazynowy=2000.0, cena_jednostkowa=0.001),
            Surowiec(nazwa='Czosnek granulowany', stan_magazynowy=500.0, cena_jednostkowa=0.05),
            Surowiec(nazwa='Pieprz czarny', stan_magazynowy=300.0, cena_jednostkowa=0.08),
            Surowiec(nazwa='Oregano', stan_magazynowy=200.0, cena_jednostkowa=0.15)
        ]
        
        for surowiec in surowce:
            db.session.add(surowiec)
        
        db.session.commit()
        
        # Dodaj przykładowe produkty
        produkty = [
            Produkt(nazwa='KuraLover', opis='Mieszanka przypraw do kurczaka'),
            Produkt(nazwa='Ziemniak Rulezzz', opis='Mieszanka przypraw do ziemniaków')
        ]
        
        for produkt in produkty:
            db.session.add(produkt)
        
        db.session.commit()

# Trasy główne
@app.route('/')
def index():
    return render_template('index.html')

# API dla surowców
@app.route('/api/surowce', methods=['GET'])
def get_surowce():
    surowce = Surowiec.query.all()
    return jsonify([s.to_dict() for s in surowce])

@app.route('/api/surowce', methods=['POST'])
def add_surowiec():
    data = request.json
    surowiec = Surowiec(
        nazwa=data['nazwa'],
        stan_magazynowy=data.get('stan_magazynowy', 0.0),
        cena_jednostkowa=data.get('cena_jednostkowa', 0.0)
    )
    db.session.add(surowiec)
    db.session.commit()
    return jsonify(surowiec.to_dict()), 201

@app.route('/api/surowce/<int:id>', methods=['PUT'])
def update_surowiec(id):
    surowiec = Surowiec.query.get_or_404(id)
    data = request.json
    
    surowiec.nazwa = data.get('nazwa', surowiec.nazwa)
    surowiec.stan_magazynowy = data.get('stan_magazynowy', surowiec.stan_magazynowy)
    surowiec.cena_jednostkowa = data.get('cena_jednostkowa', surowiec.cena_jednostkowa)
    
    db.session.commit()
    return jsonify(surowiec.to_dict())

@app.route('/api/surowce/<int:id>/korekta', methods=['POST'])
def korekta_surowiec(id):
    """Manualna korekta stanu surowca w sytuacjach awaryjnych"""
    surowiec = Surowiec.query.get_or_404(id)
    data = request.json
    
    stary_stan = surowiec.stan_magazynowy
    nowy_stan = float(data.get('nowy_stan'))
    powod = data.get('powod', 'Korekta manualna')
    
    roznica = nowy_stan - stary_stan
    
    # Zapisz historię korekty
    historia_surowiec = HistoriaSurowcow(
        surowiec_id=surowiec.id,
        typ_operacji='korekta_manualna',
        zmiana=roznica,
        stan_przed=stary_stan,
        stan_po=nowy_stan,
        opis=f"Korekta manualna: {powod}"
    )
    db.session.add(historia_surowiec)
    
    # Aktualizuj stan
    surowiec.stan_magazynowy = nowy_stan
    
    db.session.commit()
    return jsonify({
        'message': 'Korekta wykonana pomyślnie',
        'surowiec': surowiec.to_dict()
    })

@app.route('/api/surowce/<int:id>', methods=['DELETE'])
def delete_surowiec(id):
    """Usuń surowiec - tylko jeśli nie jest używany w żadnej recepturze"""
    surowiec = Surowiec.query.get_or_404(id)
    
    # Sprawdź czy surowiec jest używany w recepturach
    receptury = Receptura.query.filter_by(surowiec_id=id).all()
    if receptury:
        produkty = [Produkt.query.get(r.produkt_id).nazwa for r in receptury]
        return jsonify({
            'error': f'Nie można usunąć surowca "{surowiec.nazwa}". Jest używany w recepturach: {", ".join(produkty)}'
        }), 400
    
    # Usuń historię surowca
    HistoriaSurowcow.query.filter_by(surowiec_id=id).delete()
    
    # Usuń surowiec
    db.session.delete(surowiec)
    db.session.commit()
    
    return jsonify({'message': f'Surowiec "{surowiec.nazwa}" został usunięty'}), 200

# API dla produktów
@app.route('/api/produkty', methods=['GET'])
def get_produkty():
    produkty = Produkt.query.all()
    result = []
    
    for produkt in produkty:
        produkt_dict = produkt.to_dict()
        
        # Oblicz maksymalną produkcję i szczegóły dla każdego surowca
        receptury = Receptura.query.filter_by(produkt_id=produkt.id).all()
        
        if not receptury:
            produkt_dict['max_produkcja'] = 0
            produkt_dict['ograniczajacy_surowiec'] = 'Brak receptury'
            produkt_dict['surowce_details'] = []
        else:
            min_mozliwa_produkcja = float('inf')
            ograniczajacy_surowiec = ''
            surowce_details = []
            
            for receptura in receptury:
                surowiec = Surowiec.query.get(receptura.surowiec_id)
                if surowiec:
                    # Oblicz ile gramów produktu można wyprodukować z tego surowca
                    mozliwa_produkcja_gram = (surowiec.stan_magazynowy / receptura.ilosc_na_100g) * 100
                    # Przelicz na słoiki
                    mozliwa_produkcja_sloiki = mozliwa_produkcja_gram / produkt.gramatura_sloika
                    
                    # Dodaj szczegóły dla tego surowca
                    surowce_details.append({
                        'nazwa': surowiec.nazwa,
                        'stan_dostepny': round(surowiec.stan_magazynowy, 1),
                        'ilosc_na_sloik': round(receptura.ilosc_na_100g * produkt.gramatura_sloika / 100, 1),
                        'max_sloikow': int(mozliwa_produkcja_sloiki)
                    })
                    
                    if mozliwa_produkcja_sloiki < min_mozliwa_produkcja:
                        min_mozliwa_produkcja = mozliwa_produkcja_sloiki
                        ograniczajacy_surowiec = surowiec.nazwa
            
            produkt_dict['max_produkcja'] = int(min_mozliwa_produkcja) if min_mozliwa_produkcja != float('inf') else 0
            produkt_dict['ograniczajacy_surowiec'] = ograniczajacy_surowiec
            produkt_dict['surowce_details'] = surowce_details
        
        result.append(produkt_dict)
    
    return jsonify(result)

@app.route('/api/produkty', methods=['POST'])
def add_produkt():
    data = request.json
    nazwa = data['nazwa']
    opis = data.get('opis', '')
    stan_poczatkowy = int(data.get('stan_magazynowy', 0))
    gramatura_sloika = float(data.get('gramatura_sloika', 100.0))
    kolor_etykiety = data.get('kolor_etykiety', '#6c757d')
    
    # Najpierw utwórz produkt z zerem na stanie
    produkt = Produkt(
        nazwa=nazwa,
        opis=opis,
        stan_magazynowy=0,
        gramatura_sloika=gramatura_sloika,
        kolor_etykiety=kolor_etykiety
    )
    db.session.add(produkt)
    db.session.flush()  # Zapisz do bazy, ale nie commituj jeszcze
    
    # Jeśli stan początkowy > 0, sprawdź recepturę i odejmij surowce
    if stan_poczatkowy > 0:
        receptury = Receptura.query.filter_by(produkt_id=produkt.id).all()
        
        if receptury:  # Jeśli produkt ma recepturę
            # Oblicz ile gramów produktu trzeba "wyprodukować"
            ilosc_gram_produktu = stan_poczatkowy * gramatura_sloika
            
            # Sprawdź dostępność surowców
            for receptura in receptury:
                potrzebna_ilosc = (receptura.ilosc_na_100g / 100) * ilosc_gram_produktu
                surowiec = Surowiec.query.get(receptura.surowiec_id)
                
                if surowiec.stan_magazynowy < potrzebna_ilosc:
                    db.session.rollback()
                    return jsonify({
                        'error': f'Niewystarczająca ilość surowca: {surowiec.nazwa}. Potrzeba: {potrzebna_ilosc:.1f}g, dostępne: {surowiec.stan_magazynowy:.1f}g'
                    }), 400
            
            # Jeśli wszystko OK, odejmij surowce i zapisz historię
            for receptura in receptury:
                potrzebna_ilosc = (receptura.ilosc_na_100g / 100) * ilosc_gram_produktu
                surowiec = Surowiec.query.get(receptura.surowiec_id)
                
                # Zapisz historię surowca
                stan_przed_surowiec = surowiec.stan_magazynowy
                surowiec.stan_magazynowy -= potrzebna_ilosc
                stan_po_surowiec = surowiec.stan_magazynowy
                
                historia_surowiec = HistoriaSurowcow(
                    surowiec_id=surowiec.id,
                    typ_operacji='produkcja',
                    zmiana=-potrzebna_ilosc,
                    stan_przed=stan_przed_surowiec,
                    stan_po=stan_po_surowiec,
                    opis=f"Dodanie {stan_poczatkowy} szt. {nazwa}"
                )
                db.session.add(historia_surowiec)
            
            # Zapisz historię produktu
            historia_produkt = HistoriaProduktow(
                produkt_id=produkt.id,
                typ_operacji='dodanie',
                zmiana=stan_poczatkowy,
                stan_przed=0,
                stan_po=stan_poczatkowy,
                opis=f"Dodanie {stan_poczatkowy} szt."
            )
            db.session.add(historia_produkt)
        
        # Ustaw stan produktu
        produkt.stan_magazynowy = stan_poczatkowy
    
    db.session.commit()
    return jsonify(produkt.to_dict()), 201

@app.route('/api/produkty/<int:id>', methods=['PUT'])
def update_produkt(id):
    produkt = Produkt.query.get_or_404(id)
    data = request.json
    
    stary_stan = produkt.stan_magazynowy
    nowy_stan = int(data.get('stan_magazynowy', produkt.stan_magazynowy))
    roznica = nowy_stan - stary_stan
    
    # Jeśli zwiększamy stan produktu, sprawdź recepturę i odejmij surowce
    if roznica > 0:
        receptury = Receptura.query.filter_by(produkt_id=produkt.id).all()
        
        if receptury:  # Jeśli produkt ma recepturę
            # Oblicz ile gramów produktu trzeba "wyprodukować"
            ilosc_gram_produktu = roznica * produkt.gramatura_sloika
            
            # Sprawdź dostępność surowców
            for receptura in receptury:
                potrzebna_ilosc = (receptura.ilosc_na_100g / 100) * ilosc_gram_produktu
                surowiec = Surowiec.query.get(receptura.surowiec_id)
                
                if surowiec.stan_magazynowy < potrzebna_ilosc:
                    return jsonify({
                        'error': f'Niewystarczająca ilość surowca: {surowiec.nazwa}. Potrzeba: {potrzebna_ilosc:.1f}g, dostępne: {surowiec.stan_magazynowy:.1f}g'
                    }), 400
            
            # Jeśli wszystko OK, odejmij surowce i zapisz historię
            for receptura in receptury:
                potrzebna_ilosc = (receptura.ilosc_na_100g / 100) * ilosc_gram_produktu
                surowiec = Surowiec.query.get(receptura.surowiec_id)
                
                # Zapisz historię surowca
                stan_przed_surowiec = surowiec.stan_magazynowy
                surowiec.stan_magazynowy -= potrzebna_ilosc
                stan_po_surowiec = surowiec.stan_magazynowy
                
                historia_surowiec = HistoriaSurowcow(
                    surowiec_id=surowiec.id,
                    typ_operacji='korekta',
                    zmiana=-potrzebna_ilosc,
                    stan_przed=stan_przed_surowiec,
                    stan_po=stan_po_surowiec,
                    opis=f"Korekta: dodanie {roznica} szt. {produkt.nazwa}"
                )
                db.session.add(historia_surowiec)
            
            # Zapisz historię produktu
            historia_produkt = HistoriaProduktow(
                produkt_id=produkt.id,
                typ_operacji='korekta',
                zmiana=roznica,
                stan_przed=stary_stan,
                stan_po=nowy_stan,
                opis=f"Korekta: dodanie {roznica} szt."
            )
            db.session.add(historia_produkt)
    
    # Aktualizuj dane produktu
    produkt.nazwa = data.get('nazwa', produkt.nazwa)
    produkt.opis = data.get('opis', produkt.opis)
    produkt.stan_magazynowy = nowy_stan
    produkt.gramatura_sloika = float(data.get('gramatura_sloika', produkt.gramatura_sloika))
    produkt.kolor_etykiety = data.get('kolor_etykiety', produkt.kolor_etykiety)
    
    db.session.commit()
    return jsonify(produkt.to_dict())

@app.route('/api/produkty/<int:id>/korekta', methods=['POST'])
def korekta_produkt(id):
    """Manualna korekta stanu produktu w sytuacjach awaryjnych (bez walidacji surowców)"""
    produkt = Produkt.query.get_or_404(id)
    data = request.json
    
    stary_stan = produkt.stan_magazynowy
    nowy_stan = int(data.get('nowy_stan'))
    powod = data.get('powod', 'Korekta manualna')
    
    roznica = nowy_stan - stary_stan
    
    # Zapisz historię korekty
    historia_produkt = HistoriaProduktow(
        produkt_id=produkt.id,
        typ_operacji='korekta_manualna',
        zmiana=roznica,
        stan_przed=stary_stan,
        stan_po=nowy_stan,
        opis=f"Korekta manualna: {powod}"
    )
    db.session.add(historia_produkt)
    
    # Aktualizuj stan
    produkt.stan_magazynowy = nowy_stan
    
    db.session.commit()
    return jsonify({
        'message': 'Korekta wykonana pomyślnie',
        'produkt': produkt.to_dict()
    })

@app.route('/api/produkty/<int:id>', methods=['DELETE'])
def delete_produkt(id):
    """Usuń produkt wraz z jego recepturą i historią"""
    produkt = Produkt.query.get_or_404(id)
    
    # Sprawdź czy produkt jest używany w cyklach produkcyjnych
    cykle_pozycje = CyklPozycja.query.filter_by(produkt_id=id).all()
    if cykle_pozycje:
        cykle = [CyklProdukcyjny.query.get(cp.cykl_id).nazwa for cp in cykle_pozycje]
        return jsonify({
            'error': f'Nie można usunąć produktu "{produkt.nazwa}". Jest używany w cyklach: {", ".join(set(cykle))}'
        }), 400
    
    # Usuń receptury produktu
    Receptura.query.filter_by(produkt_id=id).delete()
    
    # Usuń historię produktu
    HistoriaProduktow.query.filter_by(produkt_id=id).delete()
    
    # Usuń produkt
    db.session.delete(produkt)
    db.session.commit()
    
    return jsonify({'message': f'Produkt "{produkt.nazwa}" został usunięty wraz z recepturą'}), 200

# API dla receptur
@app.route('/api/receptury/<int:produkt_id>', methods=['GET'])
def get_receptury(produkt_id):
    receptury = Receptura.query.filter_by(produkt_id=produkt_id).all()
    return jsonify([r.to_dict() for r in receptury])

@app.route('/api/receptury', methods=['POST'])
def add_receptura():
    data = request.json
    produkt_id = data['produkt_id']
    surowiec_id = data['surowiec_id']
    
    # Sprawdź czy taki składnik już istnieje w recepturze
    existing = Receptura.query.filter_by(
        produkt_id=produkt_id,
        surowiec_id=surowiec_id
    ).first()
    
    if existing:
        surowiec = Surowiec.query.get(surowiec_id)
        return jsonify({
            'error': f'Surowiec "{surowiec.nazwa}" już istnieje w recepturze tego produktu'
        }), 400
    
    receptura = Receptura(
        produkt_id=produkt_id,
        surowiec_id=surowiec_id,
        ilosc_na_100g=data['ilosc_na_100g']
    )
    db.session.add(receptura)
    db.session.commit()
    return jsonify(receptura.to_dict()), 201

@app.route('/api/receptury/<int:id>', methods=['DELETE'])
def delete_receptura(id):
    receptura = Receptura.query.get_or_404(id)
    db.session.delete(receptura)
    db.session.commit()
    return jsonify({'message': 'Receptura została usunięta'}), 200

# API dla dostaw
@app.route('/api/dostawy', methods=['GET'])
def get_dostawy():
    dostawy = Dostawa.query.order_by(Dostawa.data.desc()).all()
    return jsonify([d.to_dict() for d in dostawy])

@app.route('/api/dostawy', methods=['POST'])
def add_dostawa():
    data = request.json
    surowiec = Surowiec.query.get(data['surowiec_id'])
    
    # Zapisz stan przed zmianą
    stan_przed = surowiec.stan_magazynowy
    ilosc = data['ilosc']
    
    dostawa = Dostawa(
        surowiec_id=data['surowiec_id'],
        ilosc=ilosc,
        cena_calkowita=data.get('cena_calkowita', 0.0)
    )
    
    # Aktualizuj stan magazynowy
    surowiec.stan_magazynowy += ilosc
    stan_po = surowiec.stan_magazynowy
    
    # Aktualizuj cenę jednostkową jeśli podano cenę
    if data.get('cena_calkowita', 0) > 0:
        surowiec.cena_jednostkowa = data['cena_calkowita'] / ilosc
    
    # Dodaj wpis do historii
    historia = HistoriaSurowcow(
        surowiec_id=data['surowiec_id'],
        typ_operacji='dostawa',
        zmiana=ilosc,
        stan_przed=stan_przed,
        stan_po=stan_po,
        opis=f"Dostawa {ilosc}g"
    )
    
    db.session.add(dostawa)
    db.session.add(historia)
    db.session.commit()
    return jsonify(dostawa.to_dict()), 201

# API dla produkcji
@app.route('/api/produkcja', methods=['GET'])
def get_produkcja():
    produkcje = Produkcja.query.order_by(Produkcja.data.desc()).all()
    return jsonify([p.to_dict() for p in produkcje])

@app.route('/api/produkcja', methods=['POST'])
def add_produkcja():
    data = request.json
    produkt_id = data['produkt_id']
    ilosc_sloikow = int(data['ilosc'])  # ilość słoików do wyprodukowania
    
    produkt = Produkt.query.get(produkt_id)
    if not produkt:
        return jsonify({'error': 'Produkt nie istnieje'}), 400
    
    # Oblicz ile gramów produktu trzeba wyprodukować
    ilosc_gram_produktu = ilosc_sloikow * produkt.gramatura_sloika
    
    # Sprawdź czy można wyprodukować taką ilość
    receptury = Receptura.query.filter_by(produkt_id=produkt_id).all()
    
    for receptura in receptury:
        potrzebna_ilosc = (receptura.ilosc_na_100g / 100) * ilosc_gram_produktu
        surowiec = Surowiec.query.get(receptura.surowiec_id)
        
        if surowiec.stan_magazynowy < potrzebna_ilosc:
            return jsonify({
                'error': f'Niewystarczająca ilość surowca: {surowiec.nazwa}. Potrzeba: {potrzebna_ilosc:.1f}g, dostępne: {surowiec.stan_magazynowy:.1f}g'
            }), 400
    
    # Jeśli wszystko OK, odejmij surowce, zwiększ stan produktu i zapisz produkcję
    for receptura in receptury:
        potrzebna_ilosc = (receptura.ilosc_na_100g / 100) * ilosc_gram_produktu
        surowiec = Surowiec.query.get(receptura.surowiec_id)
        
        # Zapisz historię surowca
        stan_przed_surowiec = surowiec.stan_magazynowy
        surowiec.stan_magazynowy -= potrzebna_ilosc
        stan_po_surowiec = surowiec.stan_magazynowy
        
        historia_surowiec = HistoriaSurowcow(
            surowiec_id=surowiec.id,
            typ_operacji='produkcja',
            zmiana=-potrzebna_ilosc,
            stan_przed=stan_przed_surowiec,
            stan_po=stan_po_surowiec,
            opis=f"Produkcja {ilosc_sloikow} szt. {produkt.nazwa}"
        )
        db.session.add(historia_surowiec)
    
    # Zwiększ stan magazynowy produktu (w słoikach)
    stan_przed_produkt = produkt.stan_magazynowy
    produkt.stan_magazynowy += ilosc_sloikow
    stan_po_produkt = produkt.stan_magazynowy
    
    # Zapisz historię produktu
    historia_produkt = HistoriaProduktow(
        produkt_id=produkt_id,
        typ_operacji='produkcja',
        zmiana=ilosc_sloikow,
        stan_przed=stan_przed_produkt,
        stan_po=stan_po_produkt,
        opis=f"Produkcja {ilosc_sloikow} szt."
    )
    db.session.add(historia_produkt)
    
    produkcja = Produkcja(
        produkt_id=produkt_id,
        ilosc=ilosc_gram_produktu  # zapisujemy w gramach dla historii
    )
    
    db.session.add(produkcja)
    db.session.commit()
    return jsonify(produkcja.to_dict()), 201

# API dla potencjału produkcyjnego
@app.route('/api/potencjal', methods=['GET'])
def get_potencjal():
    produkty = Produkt.query.all()
    potencjal = []
    
    for produkt in produkty:
        receptury = Receptura.query.filter_by(produkt_id=produkt.id).all()
        
        if not receptury:
            potencjal.append({
                'produkt_id': produkt.id,
                'produkt_nazwa': produkt.nazwa,
                'max_produkcja': 0,
                'ograniczajacy_surowiec': 'Brak receptury'
            })
            continue
        
        min_mozliwa_produkcja = float('inf')
        ograniczajacy_surowiec = ''
        
        for receptura in receptury:
            surowiec = Surowiec.query.get(receptura.surowiec_id)
            # Oblicz ile gramów produktu można wyprodukować z tego surowca
            mozliwa_produkcja_gram = (surowiec.stan_magazynowy / receptura.ilosc_na_100g) * 100
            # Przelicz na słoiki
            mozliwa_produkcja_sloiki = mozliwa_produkcja_gram / produkt.gramatura_sloika
            
            if mozliwa_produkcja_sloiki < min_mozliwa_produkcja:
                min_mozliwa_produkcja = mozliwa_produkcja_sloiki
                ograniczajacy_surowiec = surowiec.nazwa
        
        potencjal.append({
            'produkt_id': produkt.id,
            'produkt_nazwa': produkt.nazwa,
            'gramatura_sloika': produkt.gramatura_sloika,
            'max_produkcja_sloiki': int(min_mozliwa_produkcja) if min_mozliwa_produkcja != float('inf') else 0,
            'max_produkcja_gramy': round(min_mozliwa_produkcja * produkt.gramatura_sloika, 1) if min_mozliwa_produkcja != float('inf') else 0,
            'ograniczajacy_surowiec': ograniczajacy_surowiec
        })
    
    return jsonify(potencjal)

# API dla historii surowców
@app.route('/api/historia/surowce/<int:surowiec_id>', methods=['GET'])
def get_historia_surowcow(surowiec_id):
    historia = HistoriaSurowcow.query.filter_by(surowiec_id=surowiec_id).order_by(HistoriaSurowcow.data.desc()).all()
    return jsonify([h.to_dict() for h in historia])

@app.route('/api/historia/surowce', methods=['GET'])
def get_all_historia_surowcow():
    historia = HistoriaSurowcow.query.order_by(HistoriaSurowcow.data.desc()).limit(100).all()
    return jsonify([h.to_dict() for h in historia])

@app.route('/api/historia/surowce/<int:id>', methods=['DELETE'])
def delete_historia_surowcow(id):
    historia = HistoriaSurowcow.query.get_or_404(id)
    surowiec = Surowiec.query.get(historia.surowiec_id)
    
    # Cofnij zmianę - odwróć operację
    surowiec.stan_magazynowy = historia.stan_przed
    
    # Usuń wpis z historii
    db.session.delete(historia)
    db.session.commit()
    
    return jsonify({
        'message': 'Operacja została cofnięta',
        'nowy_stan': surowiec.stan_magazynowy
    }), 200

# API dla historii produktów
@app.route('/api/historia/produkty/<int:produkt_id>', methods=['GET'])
def get_historia_produktow(produkt_id):
    historia = HistoriaProduktow.query.filter_by(produkt_id=produkt_id).order_by(HistoriaProduktow.data.desc()).all()
    return jsonify([h.to_dict() for h in historia])

@app.route('/api/historia/produkty', methods=['GET'])
def get_all_historia_produktow():
    historia = HistoriaProduktow.query.order_by(HistoriaProduktow.data.desc()).limit(100).all()
    return jsonify([h.to_dict() for h in historia])

@app.route('/api/historia/produkty/<int:id>', methods=['DELETE'])
def delete_historia_produktow(id):
    historia = HistoriaProduktow.query.get_or_404(id)
    produkt = Produkt.query.get(historia.produkt_id)
    
    # Cofnij zmianę - odwróć operację
    produkt.stan_magazynowy = historia.stan_przed
    
    # Usuń wpis z historii
    db.session.delete(historia)
    db.session.commit()
    
    return jsonify({
        'message': 'Operacja została cofnięta',
        'nowy_stan': produkt.stan_magazynowy
    }), 200

# API dla cykli produkcyjnych
@app.route('/api/cykle', methods=['GET'])
def get_cykle():
    cykle = CyklProdukcyjny.query.order_by(CyklProdukcyjny.data_utworzenia.desc()).all()
    return jsonify([c.to_dict() for c in cykle])

@app.route('/api/cykle/<int:id>', methods=['GET'])
def get_cykl(id):
    cykl = CyklProdukcyjny.query.get_or_404(id)
    return jsonify(cykl.to_dict())

@app.route('/api/cykle', methods=['POST'])
def create_cykl():
    data = request.json
    cykl = CyklProdukcyjny(nazwa=data['nazwa'])
    db.session.add(cykl)
    db.session.flush()
    
    # Dodaj pozycje do cyklu
    for pozycja in data.get('pozycje', []):
        cykl_pozycja = CyklPozycja(
            cykl_id=cykl.id,
            produkt_id=pozycja['produkt_id'],
            ilosc=pozycja['ilosc']
        )
        db.session.add(cykl_pozycja)
    
    db.session.commit()
    return jsonify(cykl.to_dict()), 201

@app.route('/api/cykle/<int:id>/sprawdz', methods=['GET'])
def sprawdz_cykl(id):
    """Sprawdź czy są dostępne zasoby do wykonania cyklu"""
    cykl = CyklProdukcyjny.query.get_or_404(id)
    pozycje = CyklPozycja.query.filter_by(cykl_id=id).all()
    
    # Oblicz łączne zapotrzebowanie na surowce
    zapotrzebowanie = {}  # {surowiec_id: ilosc_potrzebna}
    
    for pozycja in pozycje:
        produkt = Produkt.query.get(pozycja.produkt_id)
        receptury = Receptura.query.filter_by(produkt_id=produkt.id).all()
        
        ilosc_gram_produktu = pozycja.ilosc * produkt.gramatura_sloika
        
        for receptura in receptury:
            potrzebna_ilosc = (receptura.ilosc_na_100g / 100) * ilosc_gram_produktu
            
            if receptura.surowiec_id in zapotrzebowanie:
                zapotrzebowanie[receptura.surowiec_id] += potrzebna_ilosc
            else:
                zapotrzebowanie[receptura.surowiec_id] = potrzebna_ilosc
    
    # Sprawdź dostępność surowców
    wynik = {
        'mozliwe': True,
        'surowce': [],
        'braki': []
    }
    
    for surowiec_id, potrzebna_ilosc in zapotrzebowanie.items():
        surowiec = Surowiec.query.get(surowiec_id)
        dostepna_ilosc = surowiec.stan_magazynowy
        wystarczy = dostepna_ilosc >= potrzebna_ilosc
        
        info = {
            'surowiec_id': surowiec_id,
            'surowiec_nazwa': surowiec.nazwa,
            'potrzebna': round(potrzebna_ilosc, 1),
            'dostepna': round(dostepna_ilosc, 1),
            'wystarczy': wystarczy,
            'brakuje': round(max(0, potrzebna_ilosc - dostepna_ilosc), 1)
        }
        
        wynik['surowce'].append(info)
        
        if not wystarczy:
            wynik['mozliwe'] = False
            wynik['braki'].append(info)
    
    return jsonify(wynik)

@app.route('/api/cykle/<int:id>/wykonaj', methods=['POST'])
def wykonaj_cykl(id):
    """Wykonaj cykl produkcyjny"""
    cykl = CyklProdukcyjny.query.get_or_404(id)
    
    if cykl.status == 'wykonany':
        return jsonify({'error': 'Ten cykl został już wykonany'}), 400
    
    pozycje = CyklPozycja.query.filter_by(cykl_id=id).all()
    
    # Najpierw sprawdź czy są dostępne zasoby
    sprawdzenie = sprawdz_cykl(id)
    sprawdzenie_data = sprawdzenie.get_json()
    
    if not sprawdzenie_data['mozliwe']:
        return jsonify({
            'error': 'Brak wystarczających zasobów do wykonania cyklu',
            'braki': sprawdzenie_data['braki']
        }), 400
    
    # Wykonaj produkcję dla każdej pozycji
    for pozycja in pozycje:
        produkt = Produkt.query.get(pozycja.produkt_id)
        receptury = Receptura.query.filter_by(produkt_id=produkt.id).all()
        
        ilosc_gram_produktu = pozycja.ilosc * produkt.gramatura_sloika
        
        # Odejmij surowce
        for receptura in receptury:
            potrzebna_ilosc = (receptura.ilosc_na_100g / 100) * ilosc_gram_produktu
            surowiec = Surowiec.query.get(receptura.surowiec_id)
            
            # Zapisz historię surowca
            stan_przed_surowiec = surowiec.stan_magazynowy
            surowiec.stan_magazynowy -= potrzebna_ilosc
            stan_po_surowiec = surowiec.stan_magazynowy
            
            historia_surowiec = HistoriaSurowcow(
                surowiec_id=surowiec.id,
                typ_operacji='cykl',
                zmiana=-potrzebna_ilosc,
                stan_przed=stan_przed_surowiec,
                stan_po=stan_po_surowiec,
                opis=f"Cykl: {cykl.nazwa} - {pozycja.ilosc} szt. {produkt.nazwa}"
            )
            db.session.add(historia_surowiec)
        
        # Zwiększ stan produktu
        stan_przed_produkt = produkt.stan_magazynowy
        produkt.stan_magazynowy += pozycja.ilosc
        stan_po_produkt = produkt.stan_magazynowy
        
        # Zapisz historię produktu
        historia_produkt = HistoriaProduktow(
            produkt_id=produkt.id,
            typ_operacji='cykl',
            zmiana=pozycja.ilosc,
            stan_przed=stan_przed_produkt,
            stan_po=stan_po_produkt,
            opis=f"Cykl: {cykl.nazwa}"
        )
        db.session.add(historia_produkt)
        
        # Zapisz produkcję
        produkcja = Produkcja(
            produkt_id=produkt.id,
            ilosc=ilosc_gram_produktu
        )
        db.session.add(produkcja)
    
    # Oznacz cykl jako wykonany
    cykl.status = 'wykonany'
    cykl.data_wykonania = datetime.utcnow()
    
    db.session.commit()
    return jsonify({
        'message': 'Cykl produkcyjny został wykonany',
        'cykl': cykl.to_dict()
    }), 200

@app.route('/api/cykle/<int:id>', methods=['DELETE'])
def delete_cykl(id):
    cykl = CyklProdukcyjny.query.get_or_404(id)
    
    if cykl.status == 'wykonany':
        return jsonify({'error': 'Nie można usunąć wykonanego cyklu'}), 400
    
    # Usuń pozycje cyklu
    CyklPozycja.query.filter_by(cykl_id=id).delete()
    
    # Usuń cykl
    db.session.delete(cykl)
    db.session.commit()
    
    return jsonify({'message': 'Cykl został usunięty'}), 200

# ============================================
# API dla integracji WooCommerce
# ============================================

@app.route('/api/woocommerce/mapowania', methods=['GET'])
def get_woocommerce_mapowania():
    """Pobierz wszystkie mapowania produktów WooCommerce"""
    mapowania = WooCommerceMapowanie.query.all()
    return jsonify([m.to_dict() for m in mapowania])

@app.route('/api/woocommerce/mapowania', methods=['POST'])
def add_woocommerce_mapowanie():
    """Dodaj nowe mapowanie produktu WooCommerce"""
    data = request.json
    wc_product_id = int(data['woocommerce_product_id'])
    produkt_id = int(data['produkt_id'])
    
    # Sprawdź czy mapowanie już istnieje
    existing = WooCommerceMapowanie.query.filter_by(woocommerce_product_id=wc_product_id).first()
    if existing:
        return jsonify({
            'error': f'Produkt WooCommerce #{wc_product_id} jest już zmapowany'
        }), 400
    
    # Sprawdź czy produkt magazynowy istnieje
    produkt = Produkt.query.get(produkt_id)
    if not produkt:
        return jsonify({'error': 'Produkt magazynowy nie istnieje'}), 404
    
    mapowanie = WooCommerceMapowanie(
        woocommerce_product_id=wc_product_id,
        produkt_id=produkt_id
    )
    db.session.add(mapowanie)
    db.session.commit()
    
    return jsonify(mapowanie.to_dict()), 201

@app.route('/api/woocommerce/mapowania/<int:id>', methods=['DELETE'])
def delete_woocommerce_mapowanie(id):
    """Usuń mapowanie produktu WooCommerce"""
    mapowanie = WooCommerceMapowanie.query.get_or_404(id)
    db.session.delete(mapowanie)
    db.session.commit()
    return jsonify({'message': 'Mapowanie zostało usunięte'}), 200

@app.route('/api/woocommerce/test', methods=['GET', 'POST'])
def woocommerce_test():
    """Prosty endpoint testowy - zawsze zwraca 200 OK"""
    print(f"\n🧪 TEST ENDPOINT - Method: {request.method}")
    print(f"Headers: {dict(request.headers)}")
    if request.method == 'POST':
        print(f"Data: {request.get_data()}")
    return jsonify({'status': 'ok', 'message': 'Test endpoint działa!'}), 200

@app.route('/api/woocommerce/webhook-simple', methods=['GET', 'POST'])
def woocommerce_webhook_simple():
    """Uproszczony webhook bez weryfikacji - do testów"""
    try:
        print(f"\n{'='*60}")
        print(f"🔔 SIMPLE WEBHOOK - Method: {request.method}")
        print(f"Headers: {dict(request.headers)}")
        
        if request.method == 'GET':
            return 'OK', 200
        
        # Pobierz dane
        payload = request.get_data()
        print(f"Payload: {payload}")
        
        if not payload:
            return 'OK', 200
        
        # Parsuj JSON
        data = json.loads(payload)
        print(f"Parsed data: {json.dumps(data, indent=2)}")
        
        # Zwróć sukces
        return 'OK', 200
        
    except Exception as e:
        print(f"ERROR: {str(e)}")
        return 'OK', 200  # Zawsze zwracaj 200 żeby WooCommerce nie pokazywał błędu

@app.route('/api/woocommerce/webhook', methods=['GET', 'POST'])
def woocommerce_webhook():
    """
    Endpoint dla webhooków WooCommerce.
    Automatycznie odejmuje produkty ze stanu magazynowego po ukończeniu zamówienia.
    """
    try:
        # LOGOWANIE - sprawdzenie czy webhook dochodzi
        logger.info("="*60)
        logger.info(f"🔔 WEBHOOK OTRZYMANY: {request.method}")
        logger.info(f"Headers: {dict(request.headers)}")
        logger.info("="*60)
        
        # Obsługa GET - test WooCommerce
        if request.method == 'GET':
            logger.info("✅ GET request - zwracam OK")
            return 'OK', 200
        
        # Pobierz dane z żądania
        payload = request.get_data()
        logger.info(f"📦 Payload length: {len(payload)} bytes")
        logger.info(f"📦 Payload preview: {payload[:500] if payload else 'EMPTY'}")
        
        # Jeśli payload jest pusty, to test WooCommerce - zwróć OK
        if not payload or len(payload) == 0:
            return jsonify({'message': 'Webhook endpoint is ready'}), 200
        
        # Weryfikacja podpisu (jeśli skonfigurowano sekret)
        # UWAGA: Weryfikacja jest OPCJONALNA - jeśli nie ma podpisu, webhook i tak zadziała
        wc_secret = app.config.get('WOOCOMMERCE_SECRET', '')
        signature = request.headers.get('X-WC-Webhook-Signature', '')
        
        if wc_secret and signature:
            # Tylko jeśli ZARÓWNO sekret JEST skonfigurowany ORAZ podpis został wysłany
            expected_signature = hmac.new(
                wc_secret.encode('utf-8'),
                payload,
                hashlib.sha256
            ).digest().hex()
            
            logger.info(f"🔐 Weryfikacja podpisu:")
            logger.info(f"   Otrzymany: {signature[:20]}...")
            logger.info(f"   Oczekiwany: {expected_signature[:20]}...")
            
            if signature != expected_signature:
                logger.warning(f"❌ Podpis nieprawidłowy!")
                # NIE zwracaj błędu - tylko zaloguj ostrzeżenie
                logger.warning(f"⚠️  OSTRZEŻENIE: Podpis nieprawidłowy, ale kontynuuję (tryb deweloperski)")
        else:
            logger.info(f"ℹ️  Weryfikacja podpisu pominięta (sekret: {bool(wc_secret)}, podpis: {bool(signature)})")
        
        # Parsuj dane JSON
        data = json.loads(payload)
        
        # Sprawdź czy to zamówienie ukończone
        order_status = data.get('status')
        if order_status != 'completed':
            return jsonify({'message': 'Zamówienie nie jest ukończone, pomijam'}), 200
        
        order_id = data.get('id')
        line_items = data.get('line_items', [])
        
        if not line_items:
            return jsonify({'message': 'Brak produktów w zamówieniu'}), 200
        
        # Przetwórz każdy produkt w zamówieniu
        updated_products = []
        errors = []
        
        for item in line_items:
            product_id = item.get('product_id')
            quantity = int(item.get('quantity', 0))
            
            if quantity <= 0:
                continue
            
            # Znajdź mapowanie
            mapowanie = WooCommerceMapowanie.query.filter_by(
                woocommerce_product_id=product_id
            ).first()
            
            if not mapowanie:
                errors.append(f'Brak mapowania dla produktu WooCommerce #{product_id}')
                continue
            
            # Pobierz produkt magazynowy
            produkt = Produkt.query.get(mapowanie.produkt_id)
            
            if not produkt:
                errors.append(f'Produkt magazynowy nie istnieje (ID: {mapowanie.produkt_id})')
                continue
            
            # Sprawdź dostępność
            if produkt.stan_magazynowy < quantity:
                errors.append(
                    f'{produkt.nazwa}: niewystarczający stan '
                    f'(zamówiono: {quantity}, dostępne: {produkt.stan_magazynowy})'
                )
                continue
            
            # Odejmij ze stanu
            stan_przed = produkt.stan_magazynowy
            produkt.stan_magazynowy -= quantity
            stan_po = produkt.stan_magazynowy
            
            # Zapisz historię
            historia = HistoriaProduktow(
                produkt_id=produkt.id,
                typ_operacji='woocommerce',
                zmiana=-quantity,
                stan_przed=stan_przed,
                stan_po=stan_po,
                opis=f'Zamówienie WooCommerce #{order_id} - sprzedano {quantity} szt.'
            )
            db.session.add(historia)
            
            updated_products.append({
                'produkt_nazwa': produkt.nazwa,
                'ilosc': quantity,
                'stan_przed': stan_przed,
                'stan_po': stan_po
            })
        
        # Zapisz zmiany
        db.session.commit()
        
        return jsonify({
            'message': 'Zamówienie przetworzone pomyślnie',
            'order_id': order_id,
            'updated_products': updated_products,
            'errors': errors if errors else None
        }), 200
        
    except json.JSONDecodeError as e:
        logger.error(f"❌ JSON DECODE ERROR: {str(e)}")
        logger.error(f"Payload: {payload}")
        return jsonify({'error': 'Nieprawidłowy format JSON'}), 400
    except Exception as e:
        logger.error(f"❌ WEBHOOK ERROR: {str(e)}")
        import traceback
        logger.error(traceback.format_exc())
        db.session.rollback()
        return jsonify({'error': str(e)}), 500

if __name__ == '__main__':
    with app.app_context():
        create_tables()
    
    # Uruchom serwer dostępny z innych urządzeń w sieci
    app.run(host='0.0.0.0', port=5001, debug=True)
