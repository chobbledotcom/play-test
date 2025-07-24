# Default Pages
# Creates the default pages needed for the application

Rails.logger.debug "Creating default pages..."

# Homepage
Page.find_or_create_by!(slug: "/") do |page|
  page.link_title = "Home"
  page.meta_title = "play-test | BS EN 14960 Inspection Logger & Database"
  page.meta_description = "Inspection management for inflatable play equipment. Log inspections and generate reports."
  page.is_snippet = false
  page.content = <<~HTML
    <article class="home-page">
      <header>
        <h1>play-test</h1>
        <p>Inspection management for inflatable play equipment</p>
        <p>Developed by <a href="https://chobble.com">chobble.com</a></p>
        <p>Released under AGPLv3 - anyone can use and improve it</p>
      </header>

      <section>
        <aside>
          <h2>Log Inspections</h2>
          <p>Record safety inspections with compliance tracking and calculations</p>
        </aside>
        <aside>
          <h2>Generate PDFs</h2>
          <p>Create PDF reports with QR codes for verification and sharing.</p>
        </aside>
        <aside>
          <h2>Search & Export</h2>
          <p>Powerful search and CSV export functionality.</p>
        </aside>
      </section>
    </article>
  HTML
end

# About page
Page.find_or_create_by!(slug: "about") do |page|
  page.link_title = "About"
  page.meta_title = "About play-test"
  page.meta_description = "Inspection management for inflatable play equipment."
  page.is_snippet = false
  page.content = <<~HTML
    <main id="about">
      <header>
        <h1>About play-test</h1>
      </header>
    #{"  "}
      <article>
        <h2>What is play-test?</h2>
        <p>play-test is a BS EN 14960 inspection logger and database for inflatable#{" "}
           playground equipment. It helps inspectors ensure compliance with#{" "}
           BS EN 14960:2019 safety standards by digitising the inspection process#{" "}
           and generating PDF reports with QR codes for easy verification.</p>

        <h2>Key Features</h2>
        <p>Track equipment with serial numbers and dimensions. Perform seven#{" "}
           comprehensive safety assessments including structure, anchorage, materials,#{" "}
           electrical (PAT), slide safety, user height, and enclosed unit checks.#{" "}
           Automatically calculate pass/fail status based on BS EN 14960:2019#{" "}
           requirements. Generate PDF or JSON reports for every unit and inspection.#{" "}
           Upload your company logo for branded PDF reports. Safety standards#{" "}
           displayed at relevant points during inspection. Export data in multiple#{" "}
           formats. Works on any device with a web browser.</p>

        <h2>Attribution & Licensing</h2>
        <p>play-test is a project by Stefan at Chobble.com, based on a Windows#{" "}
           application originally written by Spencer Elliott of#{" "}
           elliottsbouncycastlehire.co.uk. This is an independent project and is#{" "}
           not affiliated with any testing bodies or certification organisations.#{" "}
           The software is open source and licensed under the AGPLv3 license.#{" "}
           Source code is available on the project repository.</p>

        <h2>Disclaimer</h2>
        <p>This software is provided as a tool to assist with inspection#{" "}
           record-keeping and report generation. Users are responsible for ensuring#{" "}
           their inspections meet all applicable standards and regulations. The#{" "}
           software authors accept no liability for inspection outcomes or#{" "}
           regulatory compliance.</p>
      </article>
    </main>
  HTML
end

# Footer snippet
Page.find_or_create_by!(slug: "footer") do |page|
  page.link_title = "Footer"
  page.is_snippet = true
  page.content = <<~HTML
    <p>
      <strong>Privacy policy:</strong> I won't use your info for anything#{" "}
      other than contacting you about this service, which will be rare.#{" "}
      You can delete your data whenever you like.
    </p>
    <p>
      <strong>Self promo:</strong> Do you need a website, software development,#{" "}
      or honest techy advice? Get in touch with me at#{" "}
      <a rel="nofollow" href="https://chobble.com">chobble.com</a>.
    </p>
    <p>
      <a rel="nofollow" href="https://git.chobble.com/chobble/play-test">
        Source Code
      </a>
    </p>
  HTML
end

Rails.logger.debug { "Created #{Page.pages.count} pages and #{Page.snippets.count} snippets" }
