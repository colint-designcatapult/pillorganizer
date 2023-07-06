# Common Concepts

## Bin IDs

Each bin on a device is assigned a bin ID. The Monday PM bin is considered bin 0, and Sunday AM bin 13.


|        | MON | TUE | WED | THU | FRI | SAT | SUN |
|--------|-----|-----|-----|-----|-----|-----|-----|
| **AM** | 0   | 2   | 4   | 6   | 8   | 10  | 12  |
| **PM** | 1   | 3   | 5   | 7   | 9   | 11  | 13  |

## Day-Epoch (Seconds from 00)

This project needs to deal with time a lot.
Not time as in datetime, but just time... as in 8 o'clock, or 3:23.
That is to say, time without regards to the date.
Java and Dart have some utility classes for this, but the firmware doesn't.
This necessitated a more low-level time format.
You may see it referenced as **day-epoch** or **seconds from 00**.

It is simply the number of seconds since midnight.

For example, 2:24:30 AM in day-epoch format is computed like so:

```
    (3600 * 2 )     // convert hours to seconds
  + (60   * 24)     // convert minutes to seconds
  + 30              // remaining seconds
  = 5070
```

Note that timezone is not specified.
In fact, timezones wouldn't work with this format, because a time in one zone could be a different day in another.
That's something that can't be easily dealt with, so the time is treated as zoneless.

## Serial numbers and device IDs

The **serial number** of a device is derived from the MAC address, which *should* be unique on a per-device basis.
We take the MAC address with `esp_efuse_mac_get_default` and pad it with two zero bytes to make a 64-bit integer.
The backend stores serial numbers as integers but serializes them as HEX strings.
In the protobufs, they're serialized as a 64-bit integer.
As of writing, there is some discussion about using something other than MAC address, but nothing has been decided.

Device IDs are sequentially assigned numbers (Postgres sequences) in order of when they are created (provisioned for the first time).
In that sense, a device ID is a backend concept.
The firmware is unaware of its device ID, it uses its serial number for that purpose.

## Building this documentation

The documentation for this project is sourced from both Markdown files located in `/docs` and automatically (JavaDoc and Swagger).
To "compile" the markdown into a PDF, [pandoc](https://pandoc.org/) is used.
Run `/docs/build.bat` to compile the markdown files into `docs.pdf`.

To compile the backend documentation (generated from javadoc-style comments), [Doxygen](https://www.doxygen.nl/) is used
(notably *not* javadoc, since we want to generate a PDF). 
We use the LaTeX backend, which outputs a .tex document, which must be compiled into a PDF (see `/docs/latex/buiild.bat`, you need MiKTeX or another Latex distribution).

The API documentation is generated from the backend's OpenAPI annotations. 
The PDF is generated using RapiPDF.
Make sure you've compiled with Maven (needed to generate the swagger files) and run the backend, and visit http://localhost:8080/swagger-ui/.
There should be a button in the top left to download a PDF.

