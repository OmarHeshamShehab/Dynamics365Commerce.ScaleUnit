# Product Availability Panel Documentation

This document provides an overview of the files and code that make up the **Product Availability Panel** project.

---

## 📁 Project Files

### 1️⃣ `ProductAvailabilityPanel.html`
This file describes how the panel **looks** on the screen — like drawing a picture of what you want to build.

Let’s break it down:

#### 🌟 `<!DOCTYPE html>`
- This tells the browser: “I’m writing an HTML5 page!”

#### 🌟 `<html lang="en">`
- The outer wrapping for the page — like a big toy box holding everything.
- `lang="en"` means: “We are using English.”

#### 🌟 `<head>`
- Like the brain of the page. It holds the title and rules (styles) but doesn’t show on the screen.

##### Inside `<head>`:
- `<meta charset="utf-8" />`  
  Tells the computer: “This page uses special letters and symbols from the UTF-8 alphabet.”
- `<title></title>`  
  The name of the page (shows up in browser tabs). This one is empty for now.
- `<style>...</style>`  
  A list of **rules** that tell parts of the page how to look or act.

##### 📌 CSS Styles:
- `html, body { height: 100%; margin: 0; padding: 0; }`  
  👉 Make the whole page fill the space. Remove gaps (margins, padding) around it.

- `#Contos_Pos_Extensibility_Samples_ProductAvailabilityPanel { display: flex; flex-direction: column; height: 100%; }`  
  👉 The big box (the panel) stacks its pieces like building blocks (one on top of the other) and fills the space.

- `#Contos_Pos_Extensibility_Samples_ProductAvailabilityPanel_DataList { flex: 1; overflow-y: auto; }`  
  👉 The data area (where we list stores) takes up leftover space and gets a scroll bar if there’s too much stuff.

---

#### 🌟 `<body>`
- The body is what we actually see — like the front of the toy box.

##### Inside `<body>`:
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

### 2️⃣ `ProductAvailabilityPanel.ts`
This file tells the panel **how to behave** — like giving instructions to build or play with your toy.

#### 🌟 Concepts in the TypeScript code:

##### Classes and Constructor
- **Class** = Cookie cutter → makes many panels that work the same.
- **Constructor** = The steps to build the panel.

##### Interface
- Like a plan showing what the panel should have (no actual parts yet).

##### Array
- Like a row of toy boxes, each with its own item (we can pick by number).

##### Functions / Methods
- Like magic buttons that make things happen again and again.

##### If Statement
- The computer asking: “If this is true, what should I do?”

##### Promise (`then` / `catch`)
- `then` = “When my friend brings the toy, I’ll play.”
- `catch` = “If my friend trips, I’ll help.”

##### Importing Helpers
- **SimpleProductDetailsCustomControlBase**: Recipe for making our POS panel.
- **ISimpleProductDetailsCustomControlState**: Plan of what info the panel keeps.
- **ISimpleProductDetailsCustomControlContext**: Plan for what tools (loggers, services) the panel can use.
- **InventoryLookupOperationRequest / Response**: Send a letter to ask about toys; wait for reply.
- **ClientEntities / ProxyEntities**: Blueprints for things like products, stores.
- **ArrayExtensions**: Helpers for working with rows of boxes (arrays).
- **Controls**: Building blocks like buttons, lists.

##### Control Handlers
- **DataList**: Like a table that shows rows of info neatly.

##### Template ID
- The name of the design we copy for the layout.

##### Correlation ID
- A special number to track our letters (requests and replies).

---

## 💡 Summary

- **HTML** describes what the panel looks like (the picture).
- **TypeScript** tells the panel how it works (the instructions).
