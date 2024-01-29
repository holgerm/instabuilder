# Bauregeln

## Wohnhaus Tool

```markdown
WENDE AN Wohnhaus auf Feld 0:
``````

### Wohnhaus Level 1

```markdown
WENN
UND
  Feld 0 ist leer
  Eins von Feldern 1, 3, 5, 7 ist Strasse
DANN
  BAUE auf Feld 0: Wohnhaus Level 1
```

### Wohnhaus Level 2

Wenn man eine Häuserecke auf Level 2 anhebt, wo die beiden Nachbarn bereits Level 2 Wohnhäuser haben, entsteht ein Eckhaus:

```markdown
WENN
  UND
    Feld 0 hat Wohnhaus Level 1
    ODER
      Alle Felder 1, 3 sind Wohnhaus Level 2 oder höher
      Alle Felder 3, 5 sind Wohnhaus Level 2 oder höher
      Alle Felder 5, 7 sind Wohnhaus Level 2 oder höher
      Alle Felder 7, 1 sind Wohnhaus Level 2 oder höher
DANN
  BAUE auf Feld 0: Wohnhaus Level 2 Eck-Variante
```

Wenn man an

```markdown
WENN
  Feld 0 hat Wohnhaus Level 1
DANN
  BAUE auf Feld 0: Wohnhaus Level 2
```


## Wohnhaus Level 3 Eckhaus

- UND
  - Feld 0 ist "Wohnhaus Level 2" (d.h. Fokusfeld ist "leer")
  - ODER
    - Eins von Feldern 1, 3, 5, 7 ist Strasse
    - Eins von Feldern 1, 3, 5, 7 ist Wohnhaus
  
## Wohnhaus Level 3 normal

- UND
  - Feld 0 ist "Wohnhaus Level 2" (d.h. Fokusfeld ist "leer")
  - ODER
    - Eins von Feldern 1, 3, 5, 7 ist Strasse
    - Eins von Feldern 1, 3, 5, 7 ist Wohnhaus

