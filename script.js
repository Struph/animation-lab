const pageData = [
  {
    leftTitle: "Kapitel 1",
    leftBody: "Platzhaltertext links. Hier kann spaeter Lore, Story oder Fraktionshintergrund stehen.",
    rightTitle: "Questseite 1",
    rightBody: "Platzhalter rechts. Zum Beispiel Questziel, Fortschritt und Belohnungen.",
    marker: "Start",
  },
  {
    leftTitle: "Kapitel 2",
    leftBody: "Platzhalter links fuer den zweiten Abschnitt. Denkbar sind Maps, Notizen oder NPC-Hinweise.",
    rightTitle: "Questseite 2",
    rightBody: "Rechts kannst du Checklisten und Fortschritt anzeigen.",
    marker: "Quests",
  },
  {
    leftTitle: "Kapitel 3",
    leftBody: "Platzhalter links fuer Bestiarium oder Ruffraktionen.",
    rightTitle: "Questseite 3",
    rightBody: "Rechts kannst du Belohnungen und Story-Fortsetzung darstellen.",
    marker: "Belohnungen",
  },
  {
    leftTitle: "Kapitel 4",
    leftBody: "Platzhalter links fuer Dungeon-Notizen oder Raidtaktiken.",
    rightTitle: "Questseite 4",
    rightBody: "Rechts kannst du Marker fuer wichtige Orte oder Aufgaben setzen.",
    marker: "Notizen",
  },
];

const book = document.getElementById("book");
const bookCover = document.getElementById("bookCover");
const coverFaction = document.getElementById("coverFaction");
const factionSelect = document.getElementById("factionSelect");
const openBookBtn = document.getElementById("openBookBtn");
const leftTitle = document.getElementById("leftTitle");
const leftBody = document.getElementById("leftBody");
const rightTitle = document.getElementById("rightTitle");
const rightBody = document.getElementById("rightBody");
const bookmarks = document.getElementById("bookmarks");
const flipOverlay = document.getElementById("flipOverlay");

let currentPage = 0;
let isFlipping = false;

function setFaction(factionKey) {
  bookCover.classList.remove("alliance", "horde");
  if (factionKey === "horde") {
    bookCover.classList.add("horde");
    coverFaction.textContent = "Horde Kodex";
  } else {
    bookCover.classList.add("alliance");
    coverFaction.textContent = "Allianz Chronik";
  }
}

function renderPage(index) {
  const page = pageData[index];
  if (!page) return;

  leftTitle.textContent = page.leftTitle;
  leftBody.textContent = page.leftBody;
  rightTitle.textContent = page.rightTitle;
  rightBody.textContent = page.rightBody;

  const buttons = bookmarks.querySelectorAll(".bookmark-btn");
  buttons.forEach((button, buttonIndex) => {
    button.classList.toggle("active", buttonIndex === index);
  });
}

function flipToPage(targetIndex) {
  if (isFlipping || targetIndex === currentPage || !pageData[targetIndex]) return;
  isFlipping = true;

  flipOverlay.classList.remove("is-flipping");
  void flipOverlay.offsetWidth;
  flipOverlay.classList.add("is-flipping");

  const onFlipDone = () => {
    currentPage = targetIndex;
    renderPage(currentPage);
    isFlipping = false;
    flipOverlay.removeEventListener("animationend", onFlipDone);
  };

  flipOverlay.addEventListener("animationend", onFlipDone);
}

function createBookmarks() {
  pageData.forEach((page, index) => {
    const button = document.createElement("button");
    button.type = "button";
    button.className = "bookmark-btn";
    button.textContent = page.marker;
    button.addEventListener("click", () => flipToPage(index));
    bookmarks.appendChild(button);
  });
}

openBookBtn.addEventListener("click", () => {
  if (!book.classList.contains("is-open")) {
    book.classList.add("is-open");
  }
});

factionSelect.addEventListener("change", (event) => {
  setFaction(event.target.value);
});

createBookmarks();
setFaction("alliance");
renderPage(currentPage);
