# GEMINI.md

## Project Overview

This is a Jekyll-based blog that uses the "Chirpy" theme. It appears to be a starter template for creating a personal blog or website. The project is configured to be deployed on GitHub Pages.

## Building and Running

### Running Locally

To run the project locally, you will need to have Ruby and Bundler installed.

1.  **Install dependencies:**
    ```bash
    make install
    ```

2.  **Run the Jekyll server:**
    ```bash
    make serve
    ```

The site should then be available at `http://localhost:4000`.

### Building for Production

The project is automatically built and deployed to GitHub Pages when changes are pushed to the `main` or `master` branch. The build process is defined in `.github/workflows/pages-deploy.yml`.

The build command is:

```bash
make build
```

The `JEKYLL_ENV` is set to `production`.

### Testing

The project uses `html-proofer` to test the generated HTML. The test command is run as part of the GitHub Actions workflow:

```bash
make test
```

## Development Conventions

*   **Content:** Blog posts are created in the `_posts` directory. New pages can be added to the `_tabs` directory.
*   **Configuration:** The main site configuration is in `_config.yml`. This includes the site title, description, social media links, etc.
*   **Dependencies:** Ruby dependencies are managed in the `Gemfile`.
*   **Styling:** The site uses the "Chirpy" Jekyll theme. Styling can be customized by overriding the theme's SASS files.
*   **Deployment:** The site is deployed to GitHub Pages using the workflow defined in `.github/workflows/pages-deploy.yml`.
