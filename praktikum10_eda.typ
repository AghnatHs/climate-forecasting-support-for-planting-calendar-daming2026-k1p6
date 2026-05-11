#set document(
  title: "Praktikum 10 - EDA Proyek Data Mining",
  author: "Kelompok 6 ",
)

#set page(
  paper: "a4",
  margin: (x: 2.2cm, y: 2.2cm),
  numbering: "1",
)

#set text(font: "New Computer Modern", size: 11pt, lang: "id")
#set par(justify: true, leading: 0.65em)

#show heading.where(level: 1): it => [
  #set text(size: 16pt, weight: "bold")
  #block(above: 1.2em, below: 0.6em)[#it.body]
]
#show heading.where(level: 2): it => [
  #set text(size: 13pt, weight: "bold")
  #block(above: 1em, below: 0.5em)[#it.body]
]
#show heading.where(level: 3): it => [
  #set text(size: 11.5pt, weight: "bold")
  #block(above: 0.8em, below: 0.4em)[#it.body]
]

#show raw.where(block: false): it => box(
  fill: luma(240),
  inset: (x: 3pt, y: 1pt),
  outset: (y: 2pt),
  radius: 2pt,
)[#text(font: "DejaVu Sans Mono", size: 9.5pt)[#it]]

// ============= COVER =============
#align(center)[
  #v(2cm)
  #text(size: 14pt, weight: "bold")[PRAKTIKUM 10 — DATA MINING]
  #v(0.3cm)
  #text(size: 12pt)[Progres Projek: Analisis Data Eksploratif (EDA)]
  #v(2cm)
  #text(size: 18pt, weight: "bold")[
    Climate Forecasting as Support for Planting Calendar
  ]
  #v(0.3cm)
  #text(size: 13pt)[Studi Kasus: Kota Bogor, 1940–2025]
  #v(3cm)
  #text(size: 12pt)[
    Kelompok 6 - P1 \
    Departemen Ilmu Komputer \
  ]
  #v(1cm)
  #text(size: 11pt)[#datetime.today().display("[day] [month repr:long] [year]")]
]

#pagebreak()

#outline(title: "Daftar Isi", indent: auto)

#pagebreak()

// ============= JUDUL PROYEK =============
= Judul Proyek

*Climate Forecasting as Support for Planting Calendar*

Pemodelan deret waktu data iklim historis Kota Bogor (1940–2025) untuk mendukung rekomendasi kalender tanam padi. Proyek dibangun dengan target prediksi 4 variabel iklim utama (suhu udara, curah hujan, kelembaban tanah, dan suhu tanah) menggunakan model SARIMAX, lalu diturunkan menjadi keputusan kesesuaian tanam.

Keputusan kesesuaian tanam diperoleh dari studi literatur mengenai pengaruh seperti suhu tanah, kelembapan udara, suhu udara dan intensitas hujan terhadap kesesuaian dalam penanaman padi.

= Sumber Data

Dataset diperoleh dari *Open-Meteo Historical Weather API*, layanan data cuaca historis gratis berbasis _ERA5 reanalysis_ (ECMWF).

#table(
  columns: (auto, 1fr),
  stroke: 0.5pt + luma(180),
  inset: 6pt,
  [*URL API*], [https://open-meteo.com/en/docs/historical-weather-api],
  [*Lokasi*], [Bogor (Lat: $-6.5944$, Long: $106.7892$)],
  [*Periode*], [1 Januari 1940 — 31 Desember 2025 (86 tahun)],
  [*Granularitas*], [Harian (daily)],
  [*Format*], [CSV],
  [*Ukuran*], [31.411 baris × 13 kolom (setelah seleksi atribut, exclude 'time')],
)

Karena rate-limit API, data diakuisisi bertahap per \~20 tahun (1940–1960, 1960–1980, 1980–2000, 2000–2026) lalu digabungkan menjadi satu dataset utuh `merged_dataset-1940-2025-bogor.csv`.

= Penjelasan Data

Dataset berisi observasi cuaca harian. Setelah seleksi, 13 atribut numerik dipertahankan untuk analisis (tabel di bawah). Atribut yang tidak relevan untuk wilayah tropis (mis. `snowfall_sum`) dan atribut redundan dihilangkan.

#table(
  columns: (auto, auto, auto, 1fr),
  stroke: 0.5pt + luma(180),
  inset: 5pt,
  align: (center, left, center, left),
  [*\#*], [*Atribut*], [*Satuan*], [*Deskripsi*],
  [1], [`time`], [date], [Tanggal observasi (YYYY-MM-DD)],
  [2], [`weather_code`], [WMO], [Kode kondisi cuaca standar WMO],
  [3], [`temperature_2m_max`], [°C], [Suhu udara maksimum harian (2m)],
  [4], [`temperature_2m_mean`], [°C], [Suhu udara rata-rata harian (2m)],
  [5], [`temperature_2m_min`], [°C], [Suhu udara minimum harian (2m)],
  [6], [`apparent_temperature_mean`], [°C], [Suhu terasa rata-rata (_feels-like_)],
  [7], [`sunshine_duration`], [s], [Durasi sinar matahari efektif],
  [8], [`cloud_cover_mean`], [%], [Tutupan awan rata-rata],
  [9], [`precipitation_sum`], [mm], [Total curah hujan harian],
  [10], [`precipitation_hours`], [jam], [Jumlah jam hujan dalam sehari],
  [11], [`rain_sum`], [mm], [Total curah hujan cair harian],
  [12], [`soil_moisture_0_7cm_mean`], [m³/m³], [Kelembaban tanah lapisan permukaan (0–7 cm)],
  [13], [`soil_temperature_0_7cm_mean`], [°C], [Suhu tanah lapisan permukaan (0–7 cm)],
  [14], [`relative_humidity_2m_mean`], [%], [Kelembaban relatif udara (2m)],
)

= Langkah Pembacaan Data

== Pembacaan & Normalisasi Kolom

```python
DATASET_PATH = 'dataset/merged_dataset-1940-2025-bogor.csv'
df = pd.read_csv(DATASET_PATH, parse_dates=['time'])

# normalisasi nama kolom,, hapus satuan dalam kurung & ubah '_to_' jadi '_'
df.columns = (df.columns
              .str.replace(r'\s*\(.*\)', '', regex=True)
              .str.replace('_to_', '_'))

# ambil kolom yang diperlukan
COL_TIME = 'time' # waktu (tanggal) 0
COL_WEATHER_CODE = 'weather_code' # kode cuaca (0-99)  1
COL_TEMP_2M_MAX = 'temperature_2m_max' # suhu maksimum 2 meter (°C) 2
COL_TEMP_2M_MEAN = 'temperature_2m_mean' # suhu rata-rata 2 meter (°C) 2
COL_TEMP_2M_MIN = 'temperature_2m_min' # suhu minimum 2 meter (°C) 3
COL_APPARENT_TEMP_MEAN = 'apparent_temperature_mean' # suhu terasa rata-rata (°C) 3
COL_SUNSHINE_DURATION = 'sunshine_duration' # durasi sinar matahari (s) 4
COL_CLOUD_COVER_MEAN = 'cloud_cover_mean' # tutupan awan rata-rata (%) 5
COL_PRECIPITATION_SUM = 'precipitation_sum' # jumlah presipitasi (mm) 5
COL_PRECIPITATION_HOURS_SUM = 'precipitation_hours' # jumlah jam presipitasi (jam) 6
COL_RAIN_SUM = 'rain_sum' # jumlah hujan (mm) 7
COL_SOIL_MOIST_0_7CM_MEAN = 'soil_moisture_0_7cm_mean' # kelembaban tanah 0-7 cm rata-rata (m³/m³) 8
COL_SOIL_TEMP_0_7CM_MEAN = 'soil_temperature_0_7cm_mean' # suhu tanah 0-7 cm rata-rata (°C) 9
COL_RELATIVE_HUMIDITY_2M_MEAN = 'relative_humidity_2m_mean' # kelembaban relatif 2 meter rata-rata (%) 10

FULL_COL = [COL_TIME,COL_WEATHER_CODE, COL_TEMP_2M_MAX, COL_TEMP_2M_MEAN, COL_TEMP_2M_MIN, COL_APPARENT_TEMP_MEAN,
         COL_SUNSHINE_DURATION, COL_CLOUD_COVER_MEAN, COL_PRECIPITATION_SUM, COL_PRECIPITATION_HOURS_SUM, COL_RAIN_SUM,
         COL_SOIL_MOIST_0_7CM_MEAN, COL_SOIL_TEMP_0_7CM_MEAN, COL_RELATIVE_HUMIDITY_2M_MEAN]

df = df[FULL_COL]
df = df.set_index('time')
df.index.freq = 'D'  # set daily frequency
```

== Verifikasi Pemuatan

#table(
  columns: (auto, 1fr),
  stroke: 0.5pt + luma(180),
  inset: 5pt,
  [Jumlah baris], [31.411],
  [Jumlah kolom], [13 (setelah seleksi)],
  [Rentang waktu], [1940-01-01 → 2025-12-31],
)

= Bentuk Eksplorasi Data & Hasil

== Statistik Deskriptif

Setiap kolom numerik dihitung statistik dasar (`describe`) ditambah *koefisien variasi (CV%)* dan *range*. CV digunakan untuk membandingkan tingkat variasi antar variabel berdimensi berbeda.

```python
desc = df.describe().T
desc['cv%'] = (desc['std'] / desc['mean'] * 100).round(2)  # koefisien variasi
desc['range'] = desc['max'] - desc['min']
display(desc.style
        .format(precision=3))
```

*Hasil utama:*

#table(
  columns: (auto, auto, auto, auto),
  stroke: 0.5pt + luma(180),
  inset: 5pt,
  align: (left, right, right, right, right),
  [*Variabel*], [*Mean*], [*Std*], [*CV %*],
  [`temperature_2m_mean`], [\~24,7 °C], [0,9], [*3,7%*],
  [`sunshine_duration`], [\~35.000 s (9,7 jam)], [8.839], [25%],
  [`precipitation_sum`], [\~7,141], [7,94], [*111%*],
  [`rain_sum`], [\~7,141], [7,94], [*111%*],
  [`precipitation_hours`], [\~9 jam], [5,6], [62%],
)

*Interpretasi:*
- `temperature_2m_mean` memiliki *CV coefficient of variation rendah* 3,7 % → suhu Bogor sangat stabil sepanjang tahun
- `sunshine duration` rata rata adalah 35000 detik (≈ 9,7 jam) dengan variasi yang cukup beragam (25%)
- `precipitation_sum` memiliki *CV coefficient of variation tinggi* (111 %) → curah hujan sangat bervariasi
- `rain_sum` sama dengan `precipitation_sum` (sumber air dari hujan saja, tidak ada dari salju dll)
- `precipitation_hours` rata-rata 9 jam dengan variasi tinggi (CV 62 %) → hujan bisa sangat singkat atau berlangsung lama
- `soil temperature`, `soil moisture`, dan `relative humidity` menunjukkan variasi yang lebih rendah

== Analisis Missing Value & Duplikasi

```python
# Analisis Missing Value dan duplikasi

mv = pd.DataFrame({
    'Jumlah Missing': df.isnull().sum(),
    'Persen (%)': (df.isnull().mean() * 100).round(2)
}).sort_values('Persen (%)', ascending=False)

mv_nonzero = mv[mv['Jumlah Missing'] > 0]
print(f'Kolom dengan missing value: {len(mv_nonzero)} dari {df.shape[1]}')
display(mv_nonzero.style.background_gradient(subset=['Persen (%)'], cmap='Reds').format({'Persen (%)': '{:.2f}%'}))

dup_count = df.duplicated().sum()
print(f'Jumlah baris duplikat: {dup_count}')
```

*Hasil:* Dataset ini tidak memiliki missing value dan duplikasi.

== Distribusi Variabel & Deteksi Outlier

#figure(
  image("images/report/10_1.png", width: 100%),
  caption: [
    Distribusi Variabel
  ],
)

*Temuan:*
- Suhu (`temperature_2m_*`) — distribusi mendekati normal, simetris.
- Curah hujan (`precipitation_sum`, `rain_sum`) — positive skewed, banyak nilai nol & ekor panjang (hari hujan ekstrem
- `cloud_cover_mean` — distribusi cenderung negative skewed (langit umumnya berawan).
- `sunshine_duration` — negative skewed, cenderung memiliki durasi penyinaran sinar matahari yang cukup
- `precipitation_hours` — distribusi mendekati normal dengan nilai 0 yang banyak (saat musim kemarau / bulan kering). Dengan tidak adanya outlier.
- `soil_moisture` dan `relative_humidity` cenderung berdistribusi negative skewed, dimana tanah dan relatif kelembaban termasuk lembab


#figure(
  image("images/report/10_2.png", width: 100%),
  caption: [
    Visualisasi Box Plot
  ],
)

== Visualisasi Deret Waktu (1940–2025)

Tiga _line plot_ harian + _rolling 365 hari_ + tren linear `np.polyfit`:

- Suhu udara rata-rata (`temperature_2m_mean`)
#figure(
  image("images/report/10_3.png", width: 100%),
  caption: [
    Tren suhu udara rata rata
  ],
)
- Curah hujan harian (`precipitation_sum`)
#figure(
  image("images/report/10_4.png", width: 100%),
  caption: [
    Tren curah hujan
  ],
)
- Kelembaban tanah (`soil_moisture_0_7cm_mean`)
#figure(
  image("images/report/10_5.png", width: 100%),
  caption: [
    Tren kelembapan tanah
  ],
)
- Kelembaban udara (`relative_humidity`)
#figure(
  image("images/report/10_6.png", width: 100%),
  caption: [
    Tren kelembapan udara
  ],
)

- *Suhu* — tren linear *meningkat* secara konsisten dari. Indikasi adanya global warning dan pemanasan bumi.
- *Curah hujan* — tren linear hampir datar
- *Kelembaban tanah dan udara* — relatif stabil dengan variasi musiman tahunan, dengan penurunan tren di tahun 2010++

== Dekomposisi STL (Trend / Seasonal / Residual) Bulanan

Resample bulanan → STL `period=12, robust=True` untuk 4 series: suhu, hujan, kelembaban tanah, kelembaban udara.

```python
df_monthly = df[[...]].resample('ME').mean()
stl = STL(series, period=12, robust=True).fit()
# .observed / .trend / .seasonal / .resid
```

#figure(
  image("images/report/10_7.png", width: 100%),
  caption: [
    Dekomposisi suhu rata - rata
  ],
)
#figure(
  image("images/report/10_8.png", width: 100%),
  caption: [
    Dekomposisi curah hujan
  ],
)
#figure(
  image("images/report/10_9.png", width: 100%),
  caption: [
    Tren kelembapan tanah
  ],
)
#figure(
  image("images/report/10_10.png", width: 100%),
  caption: [
    Tren kelembapan udara
  ],
)

*Temuan:*
- *Suhu* — _trend_ naik halus 1940→2025 ($+approx 1$ °C); _seasonal_ amplitudo kecil (siklus tahunan lemah, ciri tropis).
- *Curah hujan* — terdapat _trend_ yang fluktuatif (musim kemarau, musim hujan)
- *Kelembaban tanah* — _seasonal_ jelas mengikuti pola hujan; _trend_ stabil.
- *Kelembaban udara* — pola serupa kelembaban tanah, mengikuti musim hujan.

== Pola Musiman (Boxplot per Bulan)

Boxplot tiap variabel di-_grup_ per bulan (Januari – Desember):

#figure(
  image("images/report/10_11.png", width: 100%),
  caption: [
    Pola Musiman
  ],
)

- *Musim Hujan (Okt–Apr)* — curah hujan harian rata-rata $>10$ mm, kelembaban $>85%$, suhu sedikit lebih rendah. Cocok untuk penanaman padi standar.
- *Musim Kemarau (Mei–Okt)* — curah hujan $<5$ mm/hari, _sunshine duration_ lebih panjang. Periode ini hanya cocok untuk padi jika tersedia irigasi atau penanganan air yang baik.

== Korelasi Antar Fitur (Pearson)

#figure(
  image("images/report/10_12.png", width: 100%),
  caption: [
    Korelasi Person
  ],
)

*Korelasi:*
- `temperature_2m_mean` $approx$ `apparent_temperature_mean` (\~$+0,95$) — redundan.
- `precipitation_sum` $approx$ `rain_sum` (\~$+1,0$) — identik untuk wilayah tropis.
- `cloud_cover_mean` ↔ `sunshine_duration` (\~$-0,8$) — semakin berawan, semakin sedikit sinar matahari yang menyinari.
- `relative_humidity_2m_mean` ↔ `temperature_2m_mean` (\~$-0,6$) — udara panas cenderung lebih kering.
- `precipitation_hours` ↔ `precipitation_sum` (\~$+0,7$) — lama hujan,  terakumulasi.
- `soil_moisture` ↔ `precipitation_sum` (\~$+0,3$ s.d. $+0,5$) — hujan menjadikan tanah lebih basah -> kelembabpan lebih

*Implikasi modelling:*
- Fitur kandidat _exogenous_ SARIMAX, dimana variable external mempengaruhi target variable tapi tidak sebaliknya : `relative_humidity_2m_mean`, `sunshine_duration`, `cloud_cover_mean`, `precipitation_hours`.

== Deteksi Outlier (IQR)

#figure(
  image("images/report/10_13.png", width: 100%),
  caption: [
    Deteksi Outlier Boxplot
  ],
)

_outlier_ pada `precipitation_sum` bukan error, melainkan dapat diinterpretasi kejadian hujan ekstrem (banjir, badai). Tidak dihapus, tetapi dapat dipertimbangkan transformasi (log/Box-Cox) atau penanganan robust pada saat modelling.

== Tren Iklim Jangka Panjang (Per Dekade)

#figure(
  image("images/report/10_14.png", width: 100%),
  caption: [
    Tren iklim perdekade
  ],
)

*Temuan:*
- *Suhu rata-rata per dekade naik konsisten* dari \~24,4 °C (1940-an) menuju \~25,8 °C (2020-an), indikasi adanya pemanasan global.
- *Kelembaban udara relatif* sedikit menurun seiring suhu naik.

== Klasifikasi Iklim Oldeman

Menerapkan klasifikasi *Oldeman* berbasis akumulasi hujan bulanan:

#table(
  columns: (auto, 1fr),
  stroke: 0.5pt + luma(180),
  inset: 5pt,
  [*Kategori*], [*Kriteria*],
  [Bulan Basah (BB)], [hujan $gt.eq 200$ mm/bulan],
  [Bulan Lembab (BL)], [$100 lt.eq$ hujan $lt 200$ mm/bulan],
  [Bulan Kering (BK)], [hujan $lt 100$ mm/bulan],
)

```python
def classify_oldeman(mm):
    if mm >= 200: return 'Bulan Basah (BB ≥ 200 mm)'
    elif mm >= 100: return 'Bulan Lembab (BL 100–200 mm)'
    else: return 'Bulan Kering (BK < 100 mm)'
```

#figure(
  image("images/report/10_15.png", width: 100%),
  caption: [
    Klassifikasi oldeman
  ],
)

Rata-rata bulanan jangka panjang menunjukkan *9+ Bulan Basah berturut-turut* (Oktober – April mendominasi BB), dengan bulan lembab dan kering dominasi di Juni - September.

- Bogor tergolong *Tipe Iklim A* (Oldeman) — $> 9$ Bulan Basah berturut-turut.
- *Okt–Apr*: dominan Bulan Basah ($> 200$ mm) → kondisi sangat mendukung tanam padi; risiko banjir di puncak hujan.
- *Jun–Agu*: cenderung Bulan Lembab–Kering → bergantung ketersediaan irigasi.
- *Rekomendasi musim tanam padi*: MT1 = Oktober–Maret, MT2 = April–September (dengan irigasi yang baik).

= Interpretasi Akhir EDA

#block(
  fill: luma(245),
  inset: 10pt,
  radius: 4pt,
  width: 100%,
)[
  *Ringkasan temuan EDA:*

  + *Stabilitas suhu, variabilitas hujan.* Suhu Bogor sangat stabil (CV 3,7%) sementara curah hujan sangat bervariasi (CV 111%). Modelling perlu memperlakukan dua jenis sinyal ini berbeda, suhu lebih mudah diprediksi, hujan butuh model yang menangani _spike_ ekstrem.

  + *Pola musiman kuat pada hujan & kelembaban.* STL & boxplot bulanan menunjukkan siklus tahunan ($m=12$). Pemilihan model SARIMAX cocok dengan komponen musiman bulanan untuk tahap berikutnya.

  + *Tren pemanasan jangka panjang.* Suhu rata-rata secara dekade meningkat  dari 1940-an ke 2020-an, perlu diperhatikan untuk rekomendasi kalender tanam ke depan.

  + *Redundansi kolom* `rain_sum` $approx$ `precipitation_sum`; `temperature_2m_mean` $approx$ `apparent_temperature_mean`. Salah satu dari tiap pasangan akan didrop pada tahap feature engineering.

  + *Kandidat exogenous SARIMAX.* `relative_humidity_2m_mean`, `sunshine_duration`, `cloud_cover_mean`, `precipitation_hours`.

]

