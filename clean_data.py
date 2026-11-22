import pandas as pd, glob, os, io

BASE = os.path.dirname(os.path.abspath(__file__))
RAW = os.path.join(BASE, "raw")
OUT = os.path.join(BASE, "clean", "prices_clean.csv")

frames = []
for path in glob.glob(os.path.join(RAW, "*.csv")):
    with open(path, encoding="utf-8-sig", errors="replace") as f:
        lines = f.read().splitlines()
    # skip the PSA title rows; start at  real header row
    start = next(i for i, l in enumerate(lines)
                 if l.lstrip('"').startswith("Geolocation"))
    sep = ";" if lines[start].count(";") > lines[start].count(",") else ","
    frames.append(pd.read_csv(io.StringIO("\n".join(lines[start:])), sep=sep))

raw = pd.concat(frames, ignore_index=True)

# wide (months as columns) to long (one row per month)
long = raw.melt(id_vars=["Geolocation", "Commodity"],
                var_name="period", value_name="price")

# keep only real month columns  "2023 January"; drop the extra/empty columns and footnote rows
long = long[long["period"].astype(str).str.match(r"^\d{4} [A-Za-z]+$")].copy()
long = long.dropna(subset=["Commodity"])

long["price"] = pd.to_numeric(long["price"], errors="coerce")  # '..' -> blank
long[["year", "month"]] = long["period"].str.split(" ", n=1, expand=True)
long["year"] = long["year"].astype(int)
long["date"] = pd.to_datetime(long["year"].astype(str) + " " + long["month"],
                              format="%Y %B")

# '..NCR to National Capital Region' to 'NCR', '....Palawan' to 'Palawan'
long["location"] = long["Geolocation"].str.strip(". ").str.split(" - ").str[0]

def short_name(c):
    c = c.upper()
    for key, name in [("RICE", "Rice"), ("EGG", "Eggs"), ("CHICKEN", "Chicken"),
                      ("PORK", "Pork"), ("ONION", "Red Onion")]:
        if key in c:
            return name
    return c

long["commodity"] = long["Commodity"].apply(short_name)
long["unit"] = long["Commodity"].str.upper().apply(
    lambda c: "per piece" if "1 PC" in c else "per kg")

clean = (long.dropna(subset=["price"])
             [["date", "year", "month", "location", "commodity", "unit", "price"]]
             .sort_values(["commodity", "location", "date"]))

clean.to_csv(OUT, index=False)

print(clean.shape)
print(clean.head(10))
print(clean.groupby(["commodity", "location"]).size())