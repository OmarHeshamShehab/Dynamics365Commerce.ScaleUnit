# Product Availability Panel Documentation

This document provides an overview of the files and code that make up the **Product Availability Panel** project.

---

## 📑 Table of Contents

- [📁 Project Files](#-project-files)  
  - [1️⃣ ProductAvailabilityPanel.html](#1️⃣-productavailabilitypanelhtml)  
    - [🌟 <!DOCTYPE html>](#🌟-doctype-html)  
    - [🌟 <html lang="en">](#🌟-html-langen)  
    - [🌟 <head>](#🌟-head)  
      - [Inside <head>](#inside-head)  
      - [📌 CSS Styles](#-css-styles)  
    - [🌟 <body>](#🌟-body)  
      - [Inside <body>](#inside-body)  
  - [2️⃣ ProductAvailabilityPanel.ts](#2️⃣-productavailabilitypanelts)  
    - [--- Class ---](#---class---)  
    - [--- Constructor ---](#---constructor---)  
    - [--- Interface ---](#---interface---)  
    - [--- Array (or list) ---](#---array-or-list---)  
    - [--- Function (or method) ---](#---function-or-method---)  
    - [--- If statement ---](#---if-statement---)  
    - [--- Promise ---](#---promise---)  
    - [--- Import ---](#---import---)  
    - [--- Control Handlers ---](#---control-handlers---)  
    - [--- Template ID ---](#---template-id---)  
    - [--- Correlation ID ---](#---correlation-id---)  
- [💡 Summary](#💡-summary)

---

## 📁 Project Files

### 1️⃣ ProductAvailabilityPanel.html

This file describes how the panel **looks** on the screen — like drawing a picture of what you want to build.

#### 🌟 <!DOCTYPE html>

This tells the browser: “I’m writing an HTML5 page!”

#### 🌟 <html lang="en">

- The outer wrapping for the page — like a big toy box holding everything.
- `lang="en"` means: “We are using English.”

#### 🌟 <head>

- Like the brain of the page. It holds the title and rules (styles) but doesn’t show on the screen.

##### Inside <head>

- `<meta charset="utf-8" />`  
  Tells the computer: “This page uses special letters and symbols from the UTF-8 alphabet.”
- `<title></title>`  
  The name of the page (shows up in browser tabs). This one is empty for now.
- `<style>...</style>`  
  A list of **rules** that tell parts of the page how to look or act.

##### 📌 CSS Styles

- `html, body { height: 100%; margin: 0; padding: 0; }`  
  👉 Make the whole page fill the space. Remove gaps (margins, padding) around it.
- `#Contos_Pos_Extensibility_Samples_ProductAvailabilityPanel { display: flex; flex-direction: column; height: 100%; }`  
  👉 The big box (the panel) stacks its pieces like building blocks (one on top of the other) and fills the space.
- `#Contos_Pos_Extensibility_Samples_ProductAvailabilityPanel_DataList { flex: 1; overflow-y: auto; }`  
  👉 The data area (where we list stores) takes up leftover space and gets a scroll bar if there’s too much stuff.

---

#### 🌟 <body>

- The body is what we actually see — like the front of the toy box.

##### Inside <body>

- `<div id="Contos_Pos_Extensibility_Samples_ProductAvailabilityPanel" type="text/html">`  
  👉 The big panel. It has an ID (name tag) so we can style or find it easily.  
  👉 `type="text/html"` is extra info about what kind of content it holds.
- `<h2>` (the title of our panel):  
  👉 Shows the title text (like “Product Availability”).  
  👉 `class="marginTop8 marginBottom8"`: Adds space above and below.  
  👉 `data-bind="text: title"`: A magic helper (Knockout binding) that puts in the title automatically.  
  👉 `id="..._TitleElement"`: Another name tag for styling or scripting.
- `<div id="..._DataList" class="width400 grow col">`  
  👉 This is where our table of store availability appears.  
  👉 `class="width400 grow col"`: Says how wide it is (400), that it grows, and that it stacks things vertically.  
  👉 A special POS control (like a mini table) will be placed here by the script.

---

### 2️⃣ ProductAvailabilityPanel.ts

```
/*
 * Code EXPLANATION:
 * 
 * In this code we are building a panel (a special box on the screen) that shows where a product is available.
 * Let’s look at the important programming ideas in this code:
 */
```

#### --- Class ---

A class is like a cookie cutter. It gives you the shape for a cookie. We can use it to make many cookies that look the same.  
In code, a class helps us make many objects that work the same way.

#### --- Constructor ---

A constructor is like instructions for building a new toy. When we want to make a new panel, we follow these steps to build it.

#### --- Interface ---

An interface is like a plan or drawing that shows what parts a house needs (like doors and windows), but it doesn’t build the house.  
In code, it tells us what parts an object should have.

#### --- Array (or list) ---

An array is like a row of toy boxes. Each box has something inside (like numbers or words).  
We can look inside each box by its number (first box, second box, etc).

#### --- Function (or method) ---

A function is like a magic button. When we press it, something happens.  
We can press it again and again to do the same thing.

#### --- If statement ---

An if is like asking “If it’s sunny, can I go outside and play?” The computer checks if it’s sunny and decides what to do.

#### --- Promise ---

-> .then: Imagine you ask your friend to get a toy from another room. You don’t know how long it will take.  
When your friend comes back, you want to play with the toy. .then is like saying, “When you come back, I want to play with the toy.”

-> .catch: Sometimes your friend might trip and not bring the toy. .catch is like saying, “If something goes wrong, tell me so I can help or try again.”  
In code, .catch is used to handle errors.

#### --- Import ---

Importing is like bringing your favorite toys or tools from another room so you can play or build with them here.  
Each import brings us something useful:

- SimpleProductDetailsCustomControlBase: This is like a base recipe that helps us make a special panel on our page.  
  🛍 In Commerce: It provides the basic structure and functions needed to create a custom control on the product details page in POS.  
  It ensures your custom panel fits into the POS system properly.  
  A **custom control** is a special part of the POS screen that you design to add new features or display extra information.  
  It lets you create unique panels, buttons, or lists that work with POS data and actions, beyond what the standard POS offers.

- ISimpleProductDetailsCustomControlState: This is a plan that shows what information our panel keeps track of.  
  🛍 In Commerce: It defines what data about the product or page your control can see — like product ID, name, or selection mode.

- ISimpleProductDetailsCustomControlContext: This is a plan that shows what helpers or tools our panel can use.  
  🛍 In Commerce: It gives access to POS helpers — like loggers, runtime services, control factories, etc — so your control can request data or log errors.  
  loggers (for writing messages to logs to help with debugging or tracking),  
  runtime services (for interacting with the POS system’s features or operations),  
  control factories (for creating POS controls like lists or buttons dynamically),

- InventoryLookupOperationRequest / InventoryLookupOperationResponse: These are like sending a letter asking “What toys are in the other room?” and getting an answer back.  
  🛍 In Commerce: Used to request and receive product availability information from the Commerce backend or store database.

- ClientEntities / ProxyEntities: These are big sets of blueprints for things like products or stores that we can use.  
  🛍 In Commerce: They define the structure and details of important business data objects so the POS can work with them correctly.  
  ClientEntities: These represent types and models used on the POS client side (the POS app running on the device). They help manage data that the POS interacts with directly, like cart lines, transactions, or UI-related data.  
  ProxyEntities: These represent the types that match data in the Commerce backend or database (like stores, products, prices, inventory levels). They define how POS understands and exchanges data with the backend services.  
  Together, they let your control read, display, and update business information — such as showing product names, checking inventory, or listing store locations.

- ArrayExtensions: These are special helpers that make it easier to work with a row of toy boxes (an array).  
  🛍 In Commerce: Provides helper functions to check or manipulate arrays safely (like checking if a list has elements).

- Controls: These are all the buttons, lists, and pieces we can use to build what we see on the screen.  
  🛍 In Commerce: Provides UI controls (like data lists, buttons, inputs) you can create in POS to display and interact with data.

#### --- Control Handlers ---

-> DataList: This is like a table or chart that shows our toy boxes neatly lined up, so we can see what’s in each one.  
🛍 In Commerce: A standard POS control that displays rows of data (e.g., product availability per store) in a table/grid format.

#### --- Template ID ---

The template ID is like the name of our drawing or design we want to copy and use.  
🛍 In Commerce: Identifies the HTML template used for the custom panel layout.

#### --- Correlation ID ---

A correlation ID is like putting a sticker with a number on each letter we send, so we can tell which reply matches which letter.  
🛍 In Commerce: A unique ID for each operation or request, useful for tracing and debugging actions in logs.

---

## 💡 Summary

- **HTML** describes what the panel looks like (the picture).
- **TypeScript** tells the panel how it works (the instructions).
